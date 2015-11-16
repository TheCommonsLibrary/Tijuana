class Donation < ActiveRecord::Base
  include ActsAsUserResponse
  include CustomFieldsFromContentModule
  include ActionView::Helpers::NumberHelper

  self.per_page = 10

  REASONS_TO_SHOW_USER = [
    'Expired Card',
    'Invalid Card Number',
    'Invalid Credit Card Number',
    'Card Expired',
    'Invalid CVV Number',
  ]

  has_many :transactions

  scope :active, -> { where(:active => true) }
  scope :recurring, -> { where("frequency <> 'one_off'") }
  scope :one_off, -> { where("frequency = 'one_off'") }
  scope :unflagged, -> { active.where(:flagged_since => nil) }
  scope :flagged, -> { active.where("flagged_since IS NOT NULL") }
  scope :failed_new_donation, -> { flagged.where("last_donated_at IS NULL").where("flagged_since > ?", 2.weeks.ago).order("created_at DESC") }
  scope :failed_recurring_donations, -> { flagged.recurring.where("flagged_because IS NOT NULL").order("flagged_since DESC") }
  scope :not_dismissed, -> { where(:dismissed_at => nil) }
  scope :assigned, -> { flagged.where("assigned_to IS NOT NULL") }
  scope :unassigned, -> { flagged.where(:assigned_to => nil) }
  scope :one_off_out_of_date_donation_with_trigger_id, ->(time) { joins(:user)
    .where(frequency: "one_off")
    .where('trigger_id IS NOT NULL')
    .where("last_donated_at < ?", time)
    .where("quick_donate_trigger_id IS NULL")
    .readonly(false)
  }

  attr_accessor :custom_amount_in_dollars
  attr_accessor :card_number, :card_cvv
  attr_accessor :updating
  attr_accessor :credit_card_validator


  validates :card_number, :presence => true, :if => :validate_credit_card?
  validates :name_on_card, :presence => true, :if => :validate_credit_card?
  validates :card_cvv, :format => {:with => /\A\d{3,4}\z/, :message => "is invalid"}, :if => :validate_credit_card?
  validate :validate_card_date, :if => :validate_credit_card?

  validates :payment_method, :presence => true
  validate :activemerchant_credit_card_validations, :if => "new_record? && payment_method == 'credit_card' && !quick_donation"
  validate :validate_content_module_is_a_donation_ask
  validate :card_information_entered
  validate :quickdonate_user_must_have_trigger, :if => :quick_donation?

  validates :amount_in_dollars, :numericality => {:greater_than => 0}

  before_validation :alter_expiry_year
  before_save :save_last_four_digits_of_card_number, :unless => :quick_donation?
  before_save :set_card_type, :unless => :quick_donation?

  validate :donation_covers_custom_minimum, if: -> { has_custom_form_fields? }

  def used_quick_donate?
    user.present? ? trigger_id == user.quick_donate_trigger_id : false
  end

  def donation_covers_custom_minimum
    for_each_option_field_with_selected_value_with(:minimum_donation) do |custom_field, selected_option|
      if amount_in_dollars < selected_option[:minimum_donation]
        formatted_amount = number_to_currency(selected_option[:minimum_donation])
        errors.add(custom_field[:name], "^Minimum donation amount is #{formatted_amount}")
      end
    end
  end

  CREDIT_CARD_TYPES = [:visa, :mastercard, :american_express]
  OFFLINE_PAYMENT_METHODS = [:cheque, :eftpos, :cash, :money_order, :bank_cheque]
  CANCEL_REASONS = ['Can’t afford', 'Election is over', 'Campaign is over', 'Setting-up new donation', 'Pensioner', 'Unemployed', 'Retired ', 'Intended one-off ', 'Financial other', 'Don’t agree with GetUp', 'Deceased', 'Suspended donation', 'Moved overseas', 'Other orgs', 'Prefer one-off donations', 'No reason', 'Multiple recurring ', 'Fraud', 'Bank decline ']

  def self.periodic_donations_processed_before(frequency, last_donated_before)
    # this has shortcomings; see commit
    Donation.active
      .where(frequency: frequency)
      .where("last_donated_at < ?", last_donated_before)
      .where("last_tried_at < ? OR last_tried_at IS NULL", 3.days.ago) # retry every 3 days
      .where("last_donated_at > ?", last_donated_before - 36.days) # give up after 36 days after due date
  end

  # Some NOT all overdue donations
  def self.some_of_the_periodic_donations_overdue_by(time)
    Donation.periodic_donations_processed_before "weekly", (1.week+time).ago
  end

  def self.flagged_recurring_donations(search)
    if search == 'unassigned'
      failed_recurring_donations.not_dismissed.unassigned
    elsif search == 'assigned'
      failed_recurring_donations.not_dismissed.assigned
    else
      failed_recurring_donations.not_dismissed
    end
  end

  def self.flagged_new_donations(search)
    if search == 'unassigned'
      failed_new_donation.not_dismissed.unassigned
    elsif search == 'assigned'
      failed_new_donation.not_dismissed.assigned
    else
      failed_new_donation.not_dismissed
    end
  end

  def amount_in_dollars
    self.amount_in_cents.to_f / 100
  end

  def amount_in_dollars=(dollars)
    dollars = @custom_amount_in_dollars if dollars == "other"
    self.amount_in_cents = dollars.to_s.tr('$', '').to_f * 100
  end

  def custom_amount_in_dollars=(custom_amount)
    @custom_amount_in_dollars = custom_amount
    self.amount_in_dollars = custom_amount unless custom_amount.blank?
  end

  def update_recurring_donation(attrs)
    self.card_number = attrs[:card_number] unless attrs[:card_number].blank?
    self.card_cvv = attrs[:card_cvv] unless attrs[:card_cvv].blank?
    self.card_expiry_month = attrs[:card_expiry_month] unless attrs[:card_expiry_month].blank?
    self.card_expiry_year = attrs[:card_expiry_year] unless attrs[:card_expiry_year].blank?
    self.card_type = attrs[:card_type] unless attrs[:card_type].blank?
    self.name_on_card = attrs[:name_on_card] unless attrs[:name_on_card].blank?
    self.amount_in_dollars = attrs[:amount_in_dollars] unless attrs[:amount_in_dollars].blank?
    self.frequency = attrs[:frequency] unless attrs[:frequency].blank?
    self.trigger_id = attrs[:trigger_id] unless attrs[:trigger_id].blank?
  end

  def clear_flagged_donation_fields
    self.flagged_because = self.flagged_since = self.assigned_to = self.assigned_date = self.dismissed_at = nil
  end

  private :clear_flagged_donation_fields

  def on_successful_payment
    self.last_donated_at = Time.now
    clear_flagged_donation_fields if flagged_since && (flagged_because != 'Expiring Credit Card')
    save(validate: false)
  end

  def on_failed_payment(message)
    self.flagged_since = Time.now if last_donated_at.nil?
    self.dismissed_at = nil
    self.last_tried_at = Time.now
    save(validate: false)
    if !REASONS_TO_SHOW_USER.include?(message)
      message = 'please donate with Paypal, or email donations@getup.org.au or call our donations line on (02) 8188 2888 for assistance'
    end
    errors.add(payment_method.to_sym, "payment failed - #{message}")
  end

  def update_recurring_donation?(attrs)
    attrs.each do |k, v|
      return true if !v.blank? && (v.to_s != self.send(k.to_sym).to_s)
    end
    false
  end

  def disable_recurring_trigger!()
    self.update_attributes(:active => false)
  end


  def with_claim_for_processing
    if claim_donation_for_processing
      begin
        Rails.logger.info { "Successfully claimed donation id #{id} for periodic payment processing." }
        yield
      rescue Exception => e
        undo_claim_donation_for_processing
        raise e
      end
    else
      raise PeriodicDonationError, "Could not claim donation id #{id} for periodic payment processing - are you sure there are not two concurrent cron jobs running?"
      false
    end
  end

  def claim_donation_for_processing
    @original_last_tried_at = last_tried_at
    # the magic number of 6 days is the largest number that is smaller than the shortest processing period (1 week)
    number_of_records_updated = Donation.where(id: id).where('last_tried_at < ? OR last_tried_at IS NULL', 12.hours.ago).update_all(last_tried_at: Time.now)
    successful_claim = number_of_records_updated == 1
    reload if successful_claim # if we have changed database, model needs to be made aware
    successful_claim
  end
  private :claim_donation_for_processing

  def undo_claim_donation_for_processing
    update_column(:last_tried_at, @original_last_tried_at)
  end

  def custom_amount_selected?
    !self.content_module.suggested_amounts_list.include?(self.amount_in_dollars)
  end

  def recurring?
    self.frequency.to_s != "one_off"
  end

  def cancel_recurring!(reason, cancelled_at = Time.now)
    self.active = false
    self.cancel_reason = reason
    self.cancelled_at = cancelled_at
    self.save(validate: false)
  end

  def less_than_one_month
    created_at > 1.months.ago
  end

  def self.total_by_content_module(content_module_id)
    result = Donation.select('COALESCE(SUM(transactions.amount_in_cents),0) as total').
        joins(:transactions).
        where(:donations => {:content_module_id => content_module_id}, :transactions => {:successful => true, :refunded => false}).
        group('donations.content_module_id')
    result.empty? ? 0 : result[0].total/100
  end

  def made_to
    if recurring?
      "Core Member"
    else
      page && page.page_sequence && page.page_sequence.campaign ?
        page.page_sequence.campaign.name : "GetUp!"
    end
  end

  def set_card_type
    if card_number.present?
      strip_card_number = card_number.gsub(/\s+/, '')
      case strip_card_number
        when /^4[0-9]{12}(?:[0-9]{3})?$/
          self.card_type = :visa
        when /^5[1-5][0-9]{14}$/
          self.card_type = :mastercard
        when /^3[47][0-9]{13}$/
          self.card_type = :american_express
        else
          self.card_type = nil
      end
    end
  end

  def card_supports_recurring_flag?
    card_type.nil? ||  !card_type.include?('american_express')
  end

  def copy_credit_card_details!(source)
    raise "Can only copy credit card details for quick donations" unless quick_donation?
    update_attributes!(
        trigger_id: source.trigger_id,
        card_last_four_digits: source.card_last_four_digits,
        card_expiry_month: source.card_expiry_month,
        card_expiry_year: source.card_expiry_year,
        card_type: source.card_type,
        name_on_card: source.name_on_card
    )
  end

  def credit_card
    ActiveMerchant::Billing::CreditCard.new(
        :brand => card_type,
        :first_name => name_on_card,
        :last_name => name_on_card,
        :number => card_number.gsub(/[^0-9]/, ""),
        :month => card_expiry_month,
        :year => card_expiry_year,
        :verification_value => card_cvv
    )
  end

  def get_future_last_donated_at
    commence_donation_at = Date.parse(self.content_module.commence_donation_at.to_s)
    case self.frequency.to_s
      when "weekly"
        commence_donation_at-1.week
      when "monthly"
        commence_donation_at-1.month
      when "annual"
        commence_donation_at-1.year
    end
  end

  def payment_method=(method)
    method.nil? ? super(nil) : super(method.to_s)
  end

  def by_credit_card?
    self.payment_method == "credit_card"
  end

  def can_be_used_for_quickdonate_for_page?(donation_page)
    self.by_credit_card? && donation_page == page
  end

  def use_for_quickdonate
    user.update_attribute(:quick_donate_trigger_id, self.trigger_id)
  end

  def make_recurring!
    if amount_in_dollars > AppConstants.max_make_recurring_amount
      self.amount_in_cents = AppConstants.max_make_recurring_amount * 100
    end
    self.frequency = "monthly"
    self.make_recurring_at = Time.zone.now
    save!
  end

  def update_allowed?
    return false if created_at < 15.minutes.ago
    transactions.detect{|t| t.successful? }.blank?
  end


  def validate_credit_card_indentifiers
    validate_card_date
    validate_card_last_four_digits
  end

  def can_update_anonymously?
    flagged_since || card_expired_this_month_or_next || received_any_failure_email_and_no_successful_transaction_since
  end

  def has_successful_transaction_since?(time_in_past)
    Transaction.where(donation_id: self.id, successful:true, refunded:false).where(["created_at >= ?", time_in_past]).count > 0
  end

  def has_successful_transaction?
    Transaction.where(donation_id: self.id, successful:true, refunded:false).count > 0
  end

  private

  def card_expired_this_month_or_next
    Date.new(card_expiry_year, card_expiry_month, 1) <= Date.today.end_of_month + 1
  end

  def received_any_failure_email_and_no_successful_transaction_since
    last_failure_email = DonationTriggerService.new.last_failure_email(self)
    return false unless last_failure_email
    return !has_successful_transaction_since?(last_failure_email.sent_date)
  end

  def validate_card_last_four_digits
    if !/^\d{4}$/.match(self.card_last_four_digits.to_s)
      self.errors[:card_last_four_digits] << "^Credit card last four digits is invalid"
    end
  end

  def validate_card_date
    if !/^\d+$/.match(self.card_expiry_month.to_s) || self.card_expiry_month < 1 || self.card_expiry_month >12
      self.errors[:card_expiry_month] << "^Credit card expiry month is invalid"
    end
    if !/^\d{2,4}$/.match(self.card_expiry_year.to_s)
      self.errors[:card_expiry_year] << "^Credit card expiry year is invalid"
    end
  end

  def quickdonate_user_must_have_trigger
    if user.present?
      errors.add(:user, "must have saved payment details") unless self.user.quick_donate_trigger_id.present?
    end
  end

  def alter_expiry_year
    self.card_expiry_year = "20" + card_expiry_year.to_s if card_expiry_year.to_s.length == 2
  end

  def validate_credit_card?
    (self.updating || new_record?) && payment_method == "credit_card" && !quick_donation?
  end

  def activemerchant_credit_card_validations
    if (errors[:card_expiry_month] + errors[:card_expiry_year]).empty?
      errors.add(:credit_card, "has expired") if credit_card.expired?
    end
  end

  def validate_credit_details
    card = ActiveMerchant::Billing::CreditCard.new(
        :brand => card_type,
        :first_name => name_on_card,
        :last_name => name_on_card,
        :number => card_number,
        :month => card_expiry_month,
        :year => card_expiry_year,
        :verification_value => card_cvv
    )
    card.validate
    if (!card.errors.blank?)
      card.errors.each do |key, value|
        errors.add(key.to_sym, value)
      end
    end
  end

  def save_last_four_digits_of_card_number
    self.card_last_four_digits = card_number.last(4) if (payment_method == "credit_card" && !card_number.blank?)
  end

  def validate_content_module_is_a_donation_ask
    errors.add(:content_module, "is not a donation ask") unless content_module && content_module.is_a?(DonationModule)
  end

  def card_information_entered
    if card_number.to_s.include?("X") || card_cvv.to_s.include?("X")
      errors.add(:card_number, "and cvv needs to be entered. We don't retain your card number and cvv for security reasons. Please re-enter the card number and cvv before submitting.")
    end
  end

  def self.find_page_id_for_offline_donation_campaign(campaign_id)
    return 1 if campaign_id.blank?

    query = <<sql
select pages.id from pages
inner join content_module_links on content_module_links.page_id = pages.id
inner join content_modules on content_modules.id = content_module_links.content_module_id
and content_modules.type = "DonationModule"
inner join page_sequences on page_sequences.id = pages.page_sequence_id
inner join campaigns on campaigns.id = page_sequences.campaign_id
where campaigns.id = #{campaign_id}
and pages.deleted_at is null
and page_sequences.deleted_at is null
limit 1
sql
    connection.execute(query).to_a.flatten.first
  end

  class PeriodicDonationError < StandardError
  end
end
