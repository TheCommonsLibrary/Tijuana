require 'digest/sha1'
require 'event/user_already_attending_error'

class Event < ActiveRecord::Base
  acts_as_paranoid
  acts_as_commentable
  acts_as_mappable :default_units => :kms,
                   :default_formula => :sphere,
                   :lat_column_name => :address_latitude,
                   :lng_column_name => :address_longitude
  
  include FriendlyId
  friendly_id :long_name, use: [:slugged, :history, :finders]

  belongs_to :host, :class_name => "User", :foreign_key => "host_id"
  belongs_to :get_together
  has_and_belongs_to_many :attendees, :class_name => "User", :association_foreign_key => "attendee_id", :join_table => "events_attendees"

  validates :get_together, :presence => true
  validates :host, :presence => true
  validates :address, :presence => true
  validates :address_latitude, :presence => true
  validates :address_longitude, :presence => true
  validates :capacity, :presence => true, :if => "get_together.capacity_enabled?"
  validates :date, :presence => true
  validates :name, :length => { :maximum => 100, :minimum => 3 }
  validates_each :date, :if => Proc.new { |event| !event.get_together.blank? } do |event, attr, value|
    if value.blank? || !(event.get_together.from_date..event.get_together.to_date).include?(value)
      event.errors.add attr, "should be between #{I18n.l(event.get_together.from_date)} and #{I18n.l(event.get_together.to_date)}."
    elsif value < Date.today
      event.errors.add attr, "can't be in the past."
    end
  end
  validates_each :time, :if => Proc.new { |event| !event.get_together.blank? } do |event, attr, value|
    from_time, to_time = event.get_together.has_time_restriction? ? [event.get_together.from_time_str, event.get_together.to_time_str] : ["00:00", "23:00"]
    valid_range = event.get_together.has_time_restriction? ? (event.get_together.from_time..event.get_together.to_time) : (0...2400)
    Rails.logger.info "#{from_time} #{to_time}"
    Rails.logger.info "#{valid_range.inspect}"
    Rails.logger.info "#{value.inspect}"

    if value.blank? || !(valid_range).include?(value)
      event.errors.add attr, "should be between #{from_time} and #{to_time}."
    end
  end

  validates_each :capacity do |event, attr, value|
    if value && value < event.number_of_attendees
      event.errors.add attr, 'should be greater than or equal to the number of attendees' 
    end
  end

  # after creating record auto-sends an email.. bad!
  after_create :send_confirmation_or_done_email

  MAX_ATTENDEES_TO_DISPLAY = 100

  scope :unconfirmed, lambda { { :conditions => ['confirmed_at IS NULL', ] } }
  scope :confirmed, lambda { { :conditions => ['confirmed_at IS NOT NULL and canceled_at IS NULL', ] } }
  scope :within_three_months, lambda { where(Arel::Table.new(:events)[:date].gt(3.month.ago)) }
  scope :within_a_month, lambda { where(Arel::Table.new(:events)[:date].gt(1.month.ago)) }

  @important_details = [:date, :time, :address]
  class << self; attr_reader :important_details; end

  def has_host?(user)
    user == host
  end
  
  def has_attendee?(user)
    self.attendees.include?(user)
  end

  def started?
    Time.parse(self.date.to_s + "T" +  self.time_str) < Time.zone.now
  end
  
  def time_str
    self.time.to_s.rjust(4,'0').insert(2,':')
  end

  def long_name
    return self.name unless self.get_together
    "#{self.get_together.name} #{self.name}"
  end

  def confirm!
    self.update_attributes(:confirmed_at => Time.now, :confirmation_code => nil)
    send_confirmation_done_email
  end

  def confirmed?
    !self.confirmed_at.blank?
  end

  def cancel!
    deliver_cancel_emails
    self.touch(:canceled_at)
  end

  def add_attendee!(user)
    return false if is_full?
    raise UserAlreadyAttendingError.new "User #{user.email} is already attending event #{self.name}" if self.attendees.include?(user) || self.has_host?(user)
    self.attendees << user
    deliver_attendee_notifications(user)
  end

  def capacity_remaining
    capacity - number_of_attendees if capacity.present?
  end

  def is_full?
    capacity_remaining.present? ? capacity_remaining <= 0 : false
  end

  def load_attendees
    self.attendees.limit(MAX_ATTENDEES_TO_DISPLAY)
  end

  scope :with_number_of_attendees, lambda {
    select('events.*, COUNT(events_attendees.attendee_id) AS number_of_attendees')
    .joins('LEFT JOIN events_attendees ON events_attendees.event_id = events.id')
    .group('events.id')
  }

  def number_of_attendees
    # For performance reasons, some queries pre-populate number_of_attendees, see the with_number_of_attendees scope
    read_attribute(:number_of_attendees) || attendees.size
  end

  def is_empty?
    number_of_attendees == 0
  end

  def deliver_attendee_notifications(user)
    GetTogetherMailer.thankyou_for_attending_email(self, user).deliver
    GetTogetherMailer.someone_is_attending_your_event_email(self, user).deliver
  end
  handle_asynchronously(:deliver_attendee_notifications) unless Rails.env == "test"
  private :deliver_attendee_notifications

  def cancel_attendance!(user, reason)
    return false unless self.attendees.include?(user)
    self.attendees.delete(user)
    self.save!
    deliver_attendance_canceled_notifications(user, reason)
  end

  def deliver_attendance_canceled_notifications(user, reason)
    GetTogetherMailer.someone_canceled_their_attendance_email(self, user, reason).deliver
    GetTogetherMailer.attendance_canceled_confirmation_email(self, user).deliver
  end
  handle_asynchronously(:deliver_attendance_canceled_notifications) unless Rails.env == "test"
  private :deliver_attendance_canceled_notifications

  def message_attendees(msg)
    return false if msg.blank? || number_of_attendees == 0
    GetTogetherMailer.message_attendees_email(self, msg).deliver
  end

  handle_asynchronously :message_attendees unless Rails.env == "test"

  def status
    if not confirmed?
      'unconfirmed'
    elsif canceled?
      'canceled'
    elsif is_full?
      'full'
    elsif date >= Date.today
      'open'
    else
      'ended'
    end   
  end
  
  def deliver_cancel_emails
    GetTogetherMailer.event_canceled_confirmation_email(self).deliver
    GetTogetherMailer.event_canceled_attendees_notification_email(self).deliver unless self.attendees.count == 0
  end
  private :deliver_cancel_emails
  handle_asynchronously(:deliver_cancel_emails) unless Rails.env == "test"

  def canceled?
    !self.canceled_at.blank?
  end

  def in_future?
    self.date >= Date.today
  end

  def generate_confirmation_code
    email = self.host.email
    timestamp = self.created_at.to_i
    self.confirmation_code = Digest::SHA1.hexdigest([email, timestamp, self.id].join("--"))
    self.save
  end
  private :generate_confirmation_code

  def send_confirmation_ask_email
    GetTogetherMailer.thankyou_for_hosting_email(self).deliver unless self.confirmed?
  end
  private :send_confirmation_ask_email
  handle_asynchronously(:send_confirmation_ask_email) unless Rails.env == "test"

  def send_confirmation_done_email
    GetTogetherMailer.event_created_and_public_confirmation_email(self).deliver if self.confirmed?
  end
  private :send_confirmation_done_email
  handle_asynchronously(:send_confirmation_done_email) unless Rails.env == "test"

  def send_confirmation_or_done_email
    if self.confirmed?
      send_confirmation_done_email
    else
      generate_confirmation_code
      send_confirmation_ask_email
    end
  end
end
