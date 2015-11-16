require 'string_without_smartquotes'

class Page < ActiveRecord::Base
  include CacheableModel
  include UserDetailsRequirements

  acts_as_paranoid
  acts_as_taggable
  belongs_to :page_sequence, -> { with_deleted }
  has_many :content_module_links
  has_many :content_modules, :through => :content_module_links
  has_many :users, :through => :user_activity_events
  has_many :user_activity_events
  has_many :acquisition_sources
  acts_as_list :scope => :page_sequence

  include FriendlyId
  friendly_id :name, use: [:slugged, :history, :finders, :scoped], scope: :page_sequence

  validates :page_sequence, :presence => true
  validates :name, :length => { :maximum => 64, :minimum => 3 }
  validate :has_maximum_one_standfirst_module
  validates :thankyou_email_text, no_naked_links: true, links: true
  validate :has_no_email_modules_if_aside
  validate :validate_address_collection
  validate :validate_page_does_not_override_money_value_type

  before_validation :remove_smart_quotes

  after_initialize :defaults
  
  scope :most_recent_names, -> { where("users.first_name IS NOT NULL AND users.last_name IS NOT NULL").joins(:user_activity_events => :users).order("user_activity_events.created_at DESC").limit(200) }

  acts_as_user_stampable

  def next
    Page.find_by_page_sequence_id_and_position(self.page_sequence, self.position+1)
  end

  def previous
    Page.find_by_page_sequence_id_and_position(self.page_sequence, self.position-1)
  end

  def static?
    self.page_sequence && self.page_sequence.static?
  end
  
  def has_an_ask?
    !ask_module.nil?
  end
  
  def ask_module
    self.content_modules.to_a.find { |cm| cm.is_ask? }
  end
  
  def has_a_donation?
    get_donation_module.present?
  end

  def get_donation_module
    self.content_modules.find { |cm| cm.is_a?(DonationModule) }
  end

  def quick_donate_enabled?
    dm = get_donation_module
    dm.present? ? dm.quick_donate_enabled? : false
  end

  def make_recurring_enabled?
    dm = get_donation_module
    dm.present? ? dm.make_recurring_enabled? : false
  end

  def has_tell_a_friend?
    self.content_modules.any? { |cm| cm.is_a?(TellAFriendModule) }
  end
  
  def header_content_modules
    @header_content_modules ||= find_modules_for_container(:header_content)
  end

  def main_content_modules
    @main_content_modules ||= find_modules_for_container(:main_content)
  end

  def aside_content_modules
    @aside_content_modules ||= find_modules_for_container(:aside_content)
  end

  def sidebar_content_modules
    @sidebar_content_modules ||= find_modules_for_container(:sidebar)
  end

  def all_content_modules
    header_content_modules + main_content_modules + aside_content_modules + sidebar_content_modules
  end

  def valid_main_content_modules
    main_content_modules.select(&:valid?)
  end

  def valid_aside_content_modules
    aside_content_modules.select(&:valid?)
  end

  def valid_header_content_modules
    header_content_modules.select(&:valid?)
  end

  def add_view!
    Page.update_all("views = views + 1", "id = #{id}")
  end

  def cache_key
    campaign_seed = self.page_sequence.campaign.nil? ? "static" : self.page_sequence.campaign.friendly_id
    page_sequence_seed = self.page_sequence.friendly_id
    seed = "#{self.friendly_id}/page_sequence/#{page_sequence_seed}/campaign/#{campaign_seed}"
    self.class.generate_cache_key(seed)

  end

  def reorder_main_content_modules!
    success = true
    main_content_modules = find_modules_for_container(:main_content)
    index = main_content_modules.index{|main_content_module| main_content_module.instance_of?(StandfirstModule)}
    if index
      main_content_modules.unshift(main_content_modules.delete_at(index))
      main_content_modules.each_with_index do |main_content_module, index|
        content_module_link = ContentModuleLink.where(page_id: id, content_module_id: main_content_module.id).first
        content_module_link.position = index + 1
        success = content_module_link.save && success
      end
    end
    success
  end

  def quarantined?
    try(:page_sequence).try(:quarantined?) || try(:page_sequence).try(:campaign).try(:quarantined?)
  end

  def welcome_email_disabled?
    try(:page_sequence).try(:welcome_email_disabled?)
  end

  def daisy_chain?
    page_sequence.name.starts_with?(AppConstants.daisy_chain_prefix)
  end

  private

  def defaults
    self.thankyou_email_subject ||= "Thanks for taking action!"
    self.thankyou_email_text ||= "Dear {NAME|Friend},\n\nThank you for taking action on this issue.\n\nFrom GetUp!"
  end

  def find_modules_for_container(container_id)
    content_module_links.where(:layout_container => container_id).order(:position).map(&:content_module)
  end

  def has_maximum_one_standfirst_module
    if find_modules_for_container(:main_content).select{|content_module| content_module.instance_of?(StandfirstModule)}.count > 1
      self.errors.add(:content_modules, 'Maximum of one Standfirst Module is allowed.')
    end
  end

  def has_no_email_modules_if_aside
    if find_modules_for_container(:aside_content).present? && has_modules_cannot_be_along_with_aside?
      self.errors.add(:content_modules, " - Asides are not allowed with Email Target or Email MP asks.")
    end
  end

  def has_modules_cannot_be_along_with_aside?
    find_modules_for_container(:sidebar).select{|content_module| content_module.instance_of?(EmailTargetsModule) || content_module.instance_of?(EmailMPModule)}.count > 0
  end

  def remove_smart_quotes
    self.thankyou_email_subject = thankyou_email_subject.without_smartquotes if thankyou_email_subject.present?
    self.thankyou_email_text = thankyou_email_text.without_smartquotes if thankyou_email_text.present?
  end

  def module_handles_address?
    all_content_modules.any? &:handles_address?
  end

  def validate_address_collection
    if module_handles_address?
      self.errors.add(:base, "Page must have 'postcode number', 'street address' and 'suburb' set to hidden when it has a module that collects addresses.") if required_user_details_includes_address?
    end
  end

  def validate_page_does_not_override_money_value_type
    if self.member_value_type.present? && find_modules_for_container(:sidebar).any?{|content_module| content_module.is_ask? && content_module.member_value_money_module? }
      self.errors.add(:member_value_type, ": Cannot override money value type")
    end
  end
end

