class User < ActiveRecord::Base
  include CacheableModel, EmailFormatHelper
  include PatchSingleTableInheritanceForPrivilegedUser
  include NationBuilderSyncable
  include Mergeable
  include EmailTargets
  include ElectorateBooths
  include Hpd

  acts_as_paranoid
  acts_as_taggable
  
  belongs_to :postcode
  has_many :user_activity_events
  has_many :events_hosted, :class_name => "Event", :foreign_key => "host_id"
  has_many :donations
  has_many :agra_actions
  has_many :unsubscribes
  has_many :campaign_white_lists, class_name: 'DarkFilter::CampaignWhiteList'
  has_one :quarantine, dependent: :destroy

  has_and_belongs_to_many :events_attended, :class_name => "Event", :association_foreign_key => "event_id",
                          :foreign_key => "attendee_id", :join_table => "events_attendees"

  has_one :nation_builder_user

  attr_accessor :required_user_details
  cattr_accessor :current_user
  attr_protected :id

  devise :two_factor_authenticatable, :database_authenticatable, :recoverable, :rememberable, :trackable

  validate :password_must_exist, :password_must_match, :if => :create_new_password?
  validates :email, :email_format => {:message => 'is invalid'}
  validates :email, :uniqueness => {:case_sensitive => false}
  validates :postcode, :presence => {:message => 'is invalid'}, :unless => Proc.new { |user| user.postcode_number.blank? || user.country_iso != 'AU' }

  #TODO validate user data (first_name, last_name, home_number, mobile_number, street_address, suburb)once database values has been cleaned up. see user_spec history for tests that were written and removed.

  before_validation :strip_email
  before_save :check_if_subscribing
  after_create :assign_random_value
  after_create :check_if_signed_up

  before_save :downcase_email
  before_save :tidy_old_tags
  before_save :set_address_validated_at

  scope :subscribed, -> { where(:is_member => true) }
  scope :privileged, -> { where("is_admin OR is_volunteer = ?", true) }
  scope :tagged_recently, -> { joins(:taggings).where("taggings.created_at > ?", 1.hour.ago) }

  def strip_email
    self.email = email.strip unless email.nil?
  end

  private :strip_email

  def self.possibly_required_field(field, constraints = {})
    must_be_present_if_required = {:presence => {:if => lambda { [:required, :refresh].include?((@required_user_details || {})[field]) }}}
    validates field, must_be_present_if_required.merge(constraints)
  end

  possibly_required_field :first_name, :length => {:maximum => 40}
  possibly_required_field :last_name, :length => {:maximum => 40}
  possibly_required_field :home_number, :length => {:maximum => 32}
  possibly_required_field :mobile_number, :length => {:maximum => 32}
  possibly_required_field :street_address, :length => {:maximum => 128}
  possibly_required_field :suburb, :length => {:maximum => 128}
  possibly_required_field :country_iso
  possibly_required_field :postcode_number, :length => {:maximum => 16}

  def self.find_by_email(address)
    User.where(["email = ?", address.downcase]).first unless address.nil?
  end

  def value_saved?(field)
    !self.new_record? && !self.send(field).blank? && !self.field_dirty?(field)
  end

  def field_dirty?(field)
    self.send(field.to_s + "_changed?")
  end

  def save_with_source_info!(page, ask, email, source, acquisition_source=nil, additional_data={})
    @subscribed_from_page = page
    @subscribed_from_ask = ask
    @subscribed_from_email = email
    @subscribed_from_source = source
    @subscribed_from_additional_data = additional_data
    @acquisition_source = acquisition_source
    self.save!
  end

  def save_with_source(source, options={})
    @subscribed_from_source = source
    self.save(options)
  end

  def subscribing?
    if new_record?
      is_member
    else
      is_member_changed? && is_member
    end
  end

  def did_subscribe_during?
    previously_is_member = is_member
    previously_new_record = new_record?
    yield
    saved = persisted? && !is_member_changed?
    is_member && saved && (previously_new_record || !previously_is_member)
  end

  def was_previously_unsubscribed?
    unsubscribes.not_community_run.exists?
  end

  def validate_and_always_save_email(required_user_details, user_details, page, ask, email, acquisition_source=nil)
    user_details = scrub_user_details(user_details)
    @subscribed_from_page = page
    @subscribed_from_ask = ask
    @subscribed_from_email = email
    @acquisition_source = acquisition_source

    @required_user_details = required_user_details
    original_details = self.attributes
    self.attributes = user_details

    if self.valid? # validate what user entered
      self.attributes = original_details.except(:id)
      self.update_attributes!(user_details.select { |key, value| !value.blank? }) #only save new attributes if they are valid
    elsif self.new_record? && valid_email_format?(self.email) # only save email and is_member with invalid new user
      values_to_record = self.attributes.slice('email', 'is_member')
      values_to_clear_and_record = user_details.inject({}) { |h, (k, v)| h[k] = nil; h }.merge(values_to_record)
      self.attributes = values_to_clear_and_record
      self.save!(:validate => false)
    end

    self.attributes = user_details
    self.valid?
  end

  def scrub_user_details(user_details)
    user_details = user_details.slice(
        'email', 'first_name', 'last_name', 'home_number', 'mobile_number', 'street_address',
        'suburb', 'country_iso', 'postcode_number', 'is_member').
        inject({}) { |h, (k, v)| h[k] = (v || "").strip; h }
  end

  private :scrub_user_details

  def greeting
    first_name.blank? ? nil : CGI::escapeHTML(first_name.titlecase)
  end

  def full_name
    joined = "#{first_name} #{last_name}".strip
    joined.blank? ? 'Unknown Username' : joined.titlecase
  end

  def email_field
    if first_name.present?
      "#{first_name} #{last_name}".gsub('"', "'").concat(" <#{email}>").squeeze(' ')
    else
      email
    end
  end

  def name
    full_name
  end

  def postcode_number=(number)
    @postcode_number = Postcode.add_leading_zero_if_three_digits(number)
    self.postcode = Postcode.find_by_number(@postcode_number)
    self.postcode_id = self.postcode.id if self.postcode
  end

  def postcode_number
    self.postcode ? self.postcode.number : @postcode_number
  end

  def postcode_state
    self.postcode && self.postcode.state
  end

  def postcode_number_changed?
    self.postcode_id_changed? || (self.postcode_id.blank? && self.postcode_number)
  end

  def unsubscribe!(email=nil, community_run=false, reason=nil, specifics=nil)
    self.transaction do
      if community_run
        self.is_agra_member=false
      else
        self.is_member=false
      end
      email_id = email ? email.id : nil
      unsubscribe = Unsubscribe.create!(user: self, email_id: email_id, reason: reason, specifics: specifics, community_run: community_run)
      if community_run
        user_activity_event = UserActivityEvent.agra_unsubscribed!(self, unsubscribe, email)
      else
        user_activity_event = UserActivityEvent.unsubscribed!(self, unsubscribe, email)
      end
      self.save!
      user_activity_event
    end
  end

  def set_low_volume!(email)
    update_attribute(:low_volume, true)
    UserActivityEvent.requested_less_email!(self, email)
  end

  def quarantine!(email: nil, page: nil, source: nil, agra_action: nil)
    return if quarantine
    event = UserActivityEvent.quarantined!(self, email, page, source, agra_action)
    create_quarantine!(user_activity_event: event)
  end

  alias_method :quarantined?, :quarantine

  def unquarantine!(source: nil)
    return unless quarantine
    UserActivityEvent.unquarantined!(self, source, quarantine.user_activity_event)
    self.quarantine = nil
  end

  def recurring_donations
    Donation.where(:user_id => self.id).where(:frequency => ["weekly", "monthly", "annual"])
  end

  def active_recurring_donations
    recurring_donations.where(active: true)
  end

  def flagged_donations
    Donation.where(:user_id => self.id).flagged
  end

  def enrolled_for_quick_donate?
    quick_donate_trigger_id.present?
  end

  def find_quick_donation
    Donation.find_by_trigger_id(quick_donate_trigger_id) if enrolled_for_quick_donate?
  end

  def transactions
    Transaction.includes(:donation => [:user, :page => [:page_sequence => [:campaign]]]).where('donations.user_id' => self.id)
  end

  def successful_transactions
    self.transactions.where("transactions.successful" => true)
  end

  def self.find_email_addresses_by_user_ids(user_ids)
    User.connection.execute(User.select(:email).where("id IN (?)", user_ids).to_sql).to_a.flatten
  end

  def self.update_random_values
    Rails.logger.debug { "#update_random_values: start" }
    # divide users into segments to reduce table lock time
    segment_size = 50000 # mysql will take around 1 second to update 50000 rows

    users_biggest_id = self.order(:id).last.id
    users_segments_to_update = generate_users_segment(segment_size, users_biggest_id)

    users_segments_to_update.each do |segment_start, segment_end|
      self.update_all("random = rand()", ["users.id between ? and ?", segment_start, segment_end])
    end

    Rails.logger.debug { "#update_random_values: end" }
  end

  def cache_key
    self.class.generate_cache_key(self.email)
  end

  def self.umbrella_user
    find_by_email(AppConstants.umbrella_user_email_address)
  end

  def transaction_history(options={})
    relation = Transaction.successful.joins(:donation).where(:donations => {:user_id => self.id}).order("created_at DESC")
    relation.where("transactions.created_at >= ? AND transactions.created_at <= ?", options[:from].to_time, options[:to].to_time + 1.day) unless options[:from].blank?
  end

  def needs_more_details_for_page(page)
    page.required_user_details.find { |attr, value| (value != :hidden && self.send(attr).blank?) || value == :refresh }.present?
  end

  def has_required_details_for(page)
    page.required_user_details
      .select{ |_,v| v == :required }
      .all?{ |k,_| self.send(k).present? }
  end

  def clear_attributes(attrs)
    attrs.each { |field| self.send("#{field}=", nil) }
  end

  def merge_tags!(new_tags)
    begin
      update_attributes! tag_list: (tag_list | new_tags)
    rescue ActiveRecord::RecordNotUnique
      reload
      retry
    end
  end

  def emails_received_from_trigger_service
    SentTriggerEmail.where(user_id: self.id).order("sent_date desc")
  end

  private

  def assign_random_value
    self.class.connection.execute("update users set random = rand() where id = #{self.id}")
    self.reload
  end

  before_validation do
    downcase_email
  end

  def downcase_email
    self.email = self.email.downcase if self.email
  end

  def tidy_old_tags
    self.old_tags = old_tags.split(",").map(&:strip).join(",")
  end

  def set_address_validated_at
    address_updated = self.street_address_changed? || self.suburb_changed? || self.postcode_id_changed?
    self.address_validated_at = nil if address_updated && !self.address_validated_at_changed?
  end

  def already_subscribed
    !self.new_record? && self.is_member?
  end

  def check_if_signed_up
    subscribe_user! if self.is_member
  end

  def check_if_subscribing
    subscribe_user! if is_member_changed? && is_member
  end

  def subscribe_user!
    UserActivityEvent.subscribed!(self, @subscribed_from_page, @subscribed_from_ask, @subscribed_from_email, @subscribed_from_source, @acquisition_source)
    if Rails.configuration.add_subscribed_members_to_dark_filter_experiments
      subscription_data = {page: @subscribed_from_page, ask: @subscribed_from_ask, email: @subscribed_from_email, source: @subscribed_from_source, acquisition_source: @acquisition_source.try(:id)}
      subscription_data.merge!(@subscribed_from_additional_data) if @subscribed_from_additional_data
      subscription_data.delete_if { |k, v| v.nil? }
      DarkFilter::DarkFilter.delay.consider_for_experiment(self, subscription_data)
    end
  end

  def password_must_exist
    errors.add(:password, "can't be blank") if password.blank? && !self.is_admin
  end

  def password_must_match
    errors.add(:password, "doesn't match confirmation") if password != password_confirmation && !self.is_admin
  end

  def create_new_password?
    password && password_confirmation
  end

  def need_two_factor_authentication? (request)
    false
  end
  
  def self.generate_users_segment(segment_size, users_biggest_id)
    result = []

    1.step(users_biggest_id, segment_size) do |segment_start|
      segment_end = segment_start + segment_size - 1
      segment_end = segment_end > users_biggest_id ? users_biggest_id : segment_end

      result << [segment_start, segment_end]
    end

    result
  end

end
