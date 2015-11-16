require 'string_without_smartquotes'

class GetTogether < ActiveRecord::Base
  include UserDetailsRequirements

  acts_as_paranoid
  belongs_to :campaign
  belongs_to :theme
  belongs_to :content_module
  belongs_to :managed_get_together, class_name: 'GetTogether'
  has_one :community_get_together, class_name: 'GetTogether', foreign_key: :managed_get_together_id
  has_many :events, :dependent => :destroy

  include FriendlyId
  friendly_id :name, use: [:slugged, :history, :finders]

  before_validation :remove_smart_quotes

  include SerializedOptions
  option_fields :email_body, :email_subject, :tweet_text, :html_meta_description, :facebook_image

  include SerializedOptionsWithDefaults
  option_field_with_default :event_full_message, 'This event is full'
  option_field_with_default :event_closed_message, 'This event is in the past'
  option_field_with_default :action_button_text, 'View'

  accepts_nested_attributes_for :content_module
  after_initialize :defaults

  def build_content_module(params,options={})
    self.content_module = HtmlModule.new(params)
    self.content_module = HtmlModule.create(params) if self.valid?
  end

  validates :name, :presence => true
  validates :description, :presence => true
  validates :theme, :presence => true
  validates :from_date, :presence => true
  validates :to_date, :presence => true
  validates :event_full_message, :presence => true
  validates :event_closed_message, :presence => true
  validates :action_button_text, :presence => true
  validates :search_radius, presence: true, numericality: {greater_than: 0}
  validates_format_of :redirect_url, :with => /\Ahttp(s)?/i, :allow_blank => true
  validates_each :content_module do |model, attr, value|
    model.content_module.errors.add("content", "can't be blank") if value && value.content.blank?
    model.errors["content_module.content".to_sym] = "can't be blank" if value && value.content.blank?
  end
  validate :managed_get_together_id, :managed_get_together_must_be_admin_managed, if: 'managed_get_together_id.present?'

  scope :occurs_before, lambda {|date| {:conditions => ["to_date < ?", date]}}
  scope :occurs_after, lambda {|date| {:conditions => ["to_date >= ?", date]}}

  def confirmed_events_within(search_radius, search_origin)
    events.confirmed.within(search_radius, search_origin)
  end

  def exclusion_radius
    0.9 * search_radius
  end

  def self.time_select_options
    24.times.inject({}) do |acc, i|
      acc["#{i.to_s.rjust(2,'0')}:00"] = "#{i.to_s.rjust(2,'0')}00".to_i
      acc
    end
  end

  def self.hour_select_options
    24.times.inject({}) do |acc, i|
      acc["#{i.to_s.rjust(2,'0')}"] = "#{i.to_s.rjust(2,'0')}"
      acc
    end
  end

  def self.minute_select_options
    (0...60).step(15).inject({}) do |acc, i|
      acc["#{i.to_s.rjust(2,'0')}"] = "#{i.to_s.rjust(2,'0')}"
      acc
    end
  end

  def in_future?
    self.to_date >= Date.today
  end

  def from_time_str
    self.from_time.to_s.rjust(4,'0').insert(2,':')
  end

  def to_time_str
    self.to_time.to_s.rjust(4,'0').insert(2,':')
  end

  def has_time_restriction?
    !from_time.blank? && !to_time.blank?
  end

  def get_sorted_local_events(search_origin, search_radius, search_limit, *includes)
    if is_admin_managed?
      get_local_events(self, search_origin, search_radius, includes).sort { |x,y|
        if x.capacity_remaining == y.capacity_remaining
          x.distance <=> y.distance
        else
          y.capacity_remaining <=> x.capacity_remaining
        end
      }.slice(0, search_limit)
    else
      with_managed_get_together_if_present do |get_together|
        get_local_events(get_together, search_origin, search_radius, includes).order('distance ASC').limit(search_limit)
      end
    end
  end

  private

  def with_managed_get_together_if_present
    if managed_get_together_id.present?
      result = yield(managed_get_together)
    end
    unless result.present?
      result = yield(self)
    end
    result
  end

  def get_local_events(get_together, search_origin, search_radius, *includes)
    get_together.confirmed_events_within(search_radius, :origin => search_origin).includes(includes)
  end

  def defaults
    self.host_greeting_email ||= GetTogetherEmailTemplates::THANK_YOU_FOR_HOSTING
    self.attendee_greeting_email ||= GetTogetherEmailTemplates::THANK_YOU_FOR_ATTENDING
    self.email_subject ||= "Check out this GetUp! event"
    self.email_body ||= "Why don't you check out this?"
    self.tweet_text ||= "Why don't you check out this?"
    self.html_meta_description ||= AppConstants.default_page_description
    self.facebook_image ||= "http://#{AppConstants.host}/images/public/getup_logo.png"
  end

  def remove_smart_quotes
    self.host_greeting_email = host_greeting_email.without_smartquotes if host_greeting_email.present?
    self.attendee_greeting_email = attendee_greeting_email.without_smartquotes if attendee_greeting_email.present?
  end

  def managed_get_together_must_be_admin_managed
    if managed_get_together.nil?
      errors.add(:managed_get_together_id, "Does not exist") 
    elsif !managed_get_together.is_admin_managed?
      errors.add(:managed_get_together_id, "Must be id of an admin-managed get together") 
    end
  end

end
