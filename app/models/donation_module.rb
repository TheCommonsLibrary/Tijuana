class DonationModule < ContentModule
  has_many :donations, :foreign_key => :content_module_id
  include CustomFieldsForActions
  option_fields :default_amount, :suggested_amounts, :button_text, :thermometer_threshold,
                :frequency_options, :commence_donation_at, :disable_paypal,
                :quick_donate_enabled, :quick_donate_text, :quick_donate_button_text,
                :personalised_amounts, :personalised_cap, :personalised_default_amount,
                :make_recurring_enabled, :make_recurring_header, :make_recurring_body,
                :make_recurring_button, :make_recurring_checkbox_enabled, :make_recurring_checkbox_text 

  typed_option_field :participate_in_donation_blurb_ab_test, :boolean
  typed_option_field :eligible_for_personalised_donation_tests, :boolean
  typed_option_field :use_fixed_amounts, :boolean
                
  after_initialize :defaults

  validates :button_text, :length => { :minimum => 1, :maximum => 64 }
  validates :thermometer_threshold, :numericality => { :greater_than_or_equal_to => 0 }
  validate :all_suggested_amounts_are_numerical_with_optional_asterix
  validate :default_amount_is_one_of_the_suggested_amounts
  validate :all_personalised_amounts_are_numerical_with_optional_asterix_and_percent
  validate :personalised_default_amount_is_one_of_the_personalised_amounts
  validate :one_frequency_option_must_be_the_default
  validate :no_personalised_amounts_with_recurring_donations
  validate :commence_donation_at_not_supported_by_paypal
  validates :quick_donate_text, presence: true, if: Proc.new {|f| f.quick_donate_enabled? }
  validates :quick_donate_button_text, presence: true, if: Proc.new {|f| f.quick_donate_enabled? }
  validates :make_recurring_header, presence: true, if: ->(f){ f.make_recurring_enabled? }
  validates :make_recurring_body, presence: true, if: ->(f){ f.make_recurring_enabled? }
  validates :make_recurring_button, presence: true, if: ->(f){ f.make_recurring_enabled? }
  validates :make_recurring_checkbox_text, presence: true, if: ->(f){ f.make_recurring_checkbox_enabled? }

  FREQUENCIES = [:one_off, :weekly, :monthly, :annual]
  FREQUENCY_LABELS = {
    :one_off => "Donate Once",
    :weekly => "Donate Weekly",
    :monthly => "Donate Monthly",
    :annual => "Donate Annually"
  }

  HPDA_FLOOR = 10 # for any user with lower HPDA, the HPDA_FLOOR will be used
  HPDA_CAP = 300
  
  DEFAULT_SUGGESTED_AMOUNTS = "100, 50*, 30*, 12*, 5, 3"
  DEFAULT_SUGGESTED_AMOUNTS_DEFAULT = "12"
  DEFAULT_PERSONALISED_AMOUNTS = "1500, 300*, 140*, 100, 70*, 50, 30"
  DEFAULT_PERSONALISED_AMOUNTS_DEFAULT = '70'
  RELATIVE_TO_HPD_AMOUNTS = "500%*, 300%, 200%*, 140%*, 125%*"
  BOOSTED_RELATIVE_TO_HPD_AMOUNTS = "500%*, 320%, 220%*, 160%*, 145%*"
  REDUCED_RELATIVE_TO_HPD_AMOUNTS = "300%*, 200%, 160%*, 120%*, 100%*"
  SIGNIFCANTLY_REDUCED_RELATIVE_TO_HPD_AMOUNTS = "200%*, 140%, 120%*, 100%*, 90%*"
  RELATIVE_TO_HPD_AMOUNTS_DEFAULT = '140%'
  BOOSTED_RELATIVE_TO_HPD_AMOUNTS_DEFAULT = '160%'
  REDUCED_RELATIVE_TO_HPD_AMOUNTS_DEFAULT = '120%'
  SIGNIFCANTLY_REDUCED_RELATIVE_TO_HPD_AMOUNTS_DEFAULT = '100%';

  include QuickdonateHelper

  def identifies_user?
    multistep_form_shown? && identified_user
  end
  
  def multistep_form_shown?
    true 
  end

  def identified_user
    quickdonate_cookie? && User.find_by_id(cookies.signed[:quick_donate_user_id])
  end

  def last_quick_donation
    identifies_user? && identified_user.find_quick_donation
  end

  def actions_on_page(page_id, limit=200)
    Donation.where(page_id: page_id).limit(limit)
  end

  def member_value_money_module?
    true
  end

  def custom_amount_selected?(donation_params)
    donation_params[:amount_in_dollars] == 'other'
  end

  def pre_action_data_for_logger(options)
    user = options[:user]
    hpda = hpda_if_not_using_fixed_amounts(user)
    list = amounts_list(user)
    user_known = user.present?
    { hpda: hpda,
      amounts_list: list,
      use_fixed_amounts: use_fixed_amounts,
      user_known: user_known }
  end

  def post_action_data_for_logger
    super.merge({donated_amount_in_dollars: donation.amount_in_dollars})
  end

  def handles_extended_validation?
    true
  end

  def self.frequency_select_options
    FREQUENCY_LABELS.invert
  end

  def self.for_container?(layout_container)
    layout_container == :sidebar
  end

  def donatable?
    true
  end

  def donation
    @donation ||= Donation.new(default_donation_attributes)
  end

  def find_updatable_donation(donation_id)
    if donation_id
      donation = Donation.find(donation_id)
      @donation = donation if donation.update_allowed?
    end
  end

  def update_action_attributes_and_validate(params)
    find_updatable_donation(params[:donation][:id])
    # Dodgy. Why are we validating params instead of donation. Why isn't custom amount in the donation model.
    donation.attributes = params[:donation].except(:id)
    params[:donation][:custom_amount_in_dollars] = params[:donation][:custom_amount_in_dollars].strip if params[:donation][:custom_amount_in_dollars].present?
    validate_action_attributes(params)
  end

  def take_action(user, page, email=nil, params=nil, options={})
    take_action_donation_module(user, page, email, params, options)
  end

  def take_action_donation_module(user, page, email, params, options)
    donation.user = user
    donation.page = page
    donation.email = email

    success = validate_action_attributes(params) &&
              validate_quick_donation(user)
    if success
      begin
        success = donation.save && DonationService.new.process!(donation, options)
        if success
          donation.use_for_quickdonate if user.enrolled_for_quick_donate?
          track_analytics_event('donation module', 'donated', donation.frequency, donation.amount_in_cents / 100.0)
        end
      # catch response errors (e.g. 502 proxy errors) or connection errors (e.g. 'The connection to the remote server timed out')
      rescue ActiveMerchant::ResponseError, ActiveMerchant::ConnectionError => e
        notify_user(:warning, 'Donation not processed',
                  "There was an error with your donation. Please email us on help@getup.org.au and we'll be in touch. ") unless Setting[:use_cc_logging]
        notify_email(e, :data => {:message => "ActiveMerchant error"})
        success = false
      ensure
        success = true if Setting[:use_cc_logging]
      end
    end
    success
  end

  def action_id
    donation.id
  end

  def default_amount_in_dollars(user)
    if hpda = hpda_if_not_using_fixed_amounts(user)
      base = calculate_base_for_personalisation(hpda)
      calculate_amount_or_percentage(calculate_personalised_default_amount(user, base), base)
    else
      self.default_amount
    end
  end

  def amounts_list(user)
    if hpda = hpda_if_not_using_fixed_amounts(user)
      amounts = personalised_amounts_list(user, hpda)
    else
      amounts = suggested_amounts_list(false)
    end
    amounts = amounts.map{|a| "#{a.to_i}*"} if Vanity.ab_test(:amounts_shown_on_mobile) == :all
    amounts
  end

  def hpda_if_not_using_fixed_amounts(user)
    use_fixed_amounts? || recurring? ? nil : hpda(user)
  end

  def hpda(user)
    user && user.highest_previous_donation_amount
  end
  private :hpda

  def suggested_amounts_list(convert_to_float=true)
    if convert_to_float
      self.options[:suggested_amounts].split(",").map(&:to_f)
    else
      self.options[:suggested_amounts].split(",")
    end
  end

  def include_in_relative_amounts_ab_test?(user)
    user && !!hpda_if_not_using_fixed_amounts(user)
  end

  def personalised_amounts_list(user, hpda)
    base = calculate_base_for_personalisation(hpda)
    amounts = calculate_personalised_amounts(user, base).split(",").collect do |amount_or_percentage|
      calculate_amount_or_percentage(amount_or_percentage, base)
    end

    unique_amounts = amounts.collect {|a| a.to_f }.uniq
    unique_amounts.collect do |amount|
      matching = amounts.select {|a| a.to_f == amount}
      has_star = matching.find {|m| m.include? '*'}
      has_star || matching.first
    end
  end

  def calculate_base_for_personalisation(hpda)
    cap = personalised_cap.to_i
    capped = cap > 0 && hpda > cap ? cap : hpda
    [HPDA_FLOOR, capped].max
  end

  def calculate_amount_or_percentage(amount_or_percentage, base)
    if amount_or_percentage.include? '%'
      (percent, star) = amount_or_percentage.strip.split '%'
      (percent.to_i/100.0 * base).round.to_s + (star || "")
    else
      amount_or_percentage.strip
    end
  end

  def only_allow_one_off_payment?
    frequency_options['one_off'] == 'default' && frequency_options.except('one_off').all? { |frequency, option| option == 'hidden' }
  end

  def available_frequencies_for_select
    frequency_options.reject { |frequency, option| option == 'hidden' }.map { |frequency, option| [FREQUENCY_LABELS[frequency.to_sym], frequency] }
  end

  def default_frequency
    frequency_options.find { |frequency, option| option == 'default' }.first.to_sym
  end

  def amount_raised_in_cents
    @amount_raised_in_cents ||= donations.joins(:transactions).where("transactions.successful" => true, "transactions.refunded" => false, "transactions.refund_of_id" => nil).sum("transactions.amount_in_cents")
  end

  def amount_raised_in_dollars
    amount_raised_in_cents.to_f / 100
  end

  def for_a_future_recurring_payment?
    self.commence_donation_at.present? && commence_donation_at_date.future?
  end

  def commence_donation_at_date
    Date.parse(commence_donation_at.to_s)
  end

  def paypal_disabled?
    disable_paypal.present? && disable_paypal != '0'
  end

  def quick_donate_enabled?
    quick_donate_enabled == "1"
  end

  def make_recurring_enabled?
    make_recurring_enabled == "1"
  end

  def make_recurring_checkbox_enabled?
    make_recurring_checkbox_enabled == "1"
  end

  def set_user_and_page(user, page)
    donation.user = user
    donation.page = page
  end

  def if_trackable_donation_made
    yield donation.amount_in_cents, donation.user, donation if donation
  end

  private

  def calculate_personalised_amounts(user, base)
    if !eligible_for_personalised_donation_tests? || !Vanity.context
      options[:personalised_amounts].present? ? options[:personalised_amounts] : DEFAULT_PERSONALISED_AMOUNTS
    else
      case Vanity.ab_test(:personalised_amounts_v4)
        when :static then DEFAULT_PERSONALISED_AMOUNTS
        when :relative then RELATIVE_TO_HPD_AMOUNTS
        when :relative_with_average_check
          user.average_is_less_than_half_hpd?(base) ? SIGNIFCANTLY_REDUCED_RELATIVE_TO_HPD_AMOUNTS : RELATIVE_TO_HPD_AMOUNTS
        else
          if base <= 15
            BOOSTED_RELATIVE_TO_HPD_AMOUNTS
          elsif user.donations.one_off.last.try(:created_at) > 21.days.ago
            REDUCED_RELATIVE_TO_HPD_AMOUNTS
          else
            RELATIVE_TO_HPD_AMOUNTS
          end
      end
    end
  end

  # VANITY: default for personalised_amounts
  def calculate_personalised_default_amount(user, base)
    if !eligible_for_personalised_donation_tests? || !Vanity.context
      options[:personalised_default_amount].present? ? options[:personalised_default_amount] : DEFAULT_PERSONALISED_AMOUNTS_DEFAULT
    else
      case Vanity.ab_test(:personalised_amounts_v4)
        when :static then DEFAULT_PERSONALISED_AMOUNTS_DEFAULT
        when :relative then RELATIVE_TO_HPD_AMOUNTS_DEFAULT
        when :relative_with_average_check
          user.average_is_less_than_half_hpd?(base) ? SIGNIFCANTLY_REDUCED_RELATIVE_TO_HPD_AMOUNTS_DEFAULT : RELATIVE_TO_HPD_AMOUNTS_DEFAULT
        else
          if base <= 15
            BOOSTED_RELATIVE_TO_HPD_AMOUNTS_DEFAULT
          elsif user.donations.one_off.last.try(:created_at) > 21.days.ago
            REDUCED_RELATIVE_TO_HPD_AMOUNTS_DEFAULT
          else
            RELATIVE_TO_HPD_AMOUNTS_DEFAULT
          end
      end
    end
  end

  def default_donation_attributes
    { :content_module => self,
      :frequency => default_frequency,
      :amount_in_dollars => default_amount,
      :payment_method => :credit_card
    }
  end

  def defaults
    self.button_text = "Donate!" unless self.button_text
    self.suggested_amounts = DEFAULT_SUGGESTED_AMOUNTS unless self.suggested_amounts
    self.default_amount = DEFAULT_SUGGESTED_AMOUNTS_DEFAULT unless options[:default_amount]
    self.personalised_amounts = DEFAULT_PERSONALISED_AMOUNTS unless options[:personalised_amounts]
    self.personalised_cap = HPDA_CAP.to_s unless self.personalised_cap
    self.personalised_default_amount = DEFAULT_PERSONALISED_AMOUNTS_DEFAULT unless options[:personalised_default_amount]
    self.frequency_options = {'one_off' => 'default', 'weekly' => 'hidden', 'monthly' => 'hidden', 'annual' => 'hidden'} unless self.frequency_options
    self.public_activity_stream_template = "{NAME|A member} donated to [a cause]." unless self.public_activity_stream_template
    self.quick_donate_enabled = (new_record? ? "1" : "0") unless self.quick_donate_enabled
    qd_txt = "<p>To make things easier next time, we can securely save your payment details to your GetUp account on this device. <em>Only do this if you are not using a public computer.</em></p>"
    self.quick_donate_text = (new_record? ? qd_txt : "") unless self.quick_donate_text
    self.quick_donate_button_text = (new_record? ? "Yes, remember me" : "") unless self.quick_donate_button_text
    self.use_fixed_amounts = false if self.use_fixed_amounts.nil?
    self.eligible_for_personalised_donation_tests = true if self.new_record? && eligible_for_personalised_donation_tests != false
    self.make_recurring_header = "Thanks for your donation!" unless self.make_recurring_header.present?
    self.make_recurring_body = "<p>Thank you so much for your donation. To ensure our movement thrives could you give monthly?</p><p>GetUp relies entirely on public donations to run our campaigns, and we need your support to make progressive voices heard in Australia.</p><p>Will you become a regular contributor and make it possible for GetUp to run rapid-response campaigns on crucial progressive issues into the future?</p>" unless self.make_recurring_body.present?
    self.make_recurring_button = "Donate {amount} monthly" unless self.make_recurring_button.present?
    self.make_recurring_checkbox_text = "Make my donation monthly" unless make_recurring_checkbox_text.present?
  end

  def all_suggested_amounts_are_numerical_with_optional_asterix
    incorrectly_formatted = suggested_amounts.split(",").any? {|amount| !amount.strip.match(/^[1-9][\d]*(\.[\d]+){0,1}\*{0,1}$/)}
    self.errors.add(:suggested_amounts, "must all be greater than zero and can include an optional asterix only.") if incorrectly_formatted
  end

  def all_personalised_amounts_are_numerical_with_optional_asterix_and_percent
    if options[:personalised_amounts].present?
      incorrectly_formatted = options[:personalised_amounts].split(",").any? {|amount| !amount.strip.match(/^[1-9][\d]*(\.[\d]+){0,1}%{0,1}\*{0,1}$/)}
      self.errors.add(:personalised_amounts, "must all be greater than zero, can be a percentage and can include an optional asterix only.") if incorrectly_formatted
    end
  end

  def personalised_default_amount_is_one_of_the_personalised_amounts
    # regex does:
    # 1) a look behind to check that the preceding digit (if it exists) is not a number, example:
    #    (110 =~ /10/).should be_false
    # 2) a look ahead to check that the preceding digit (if it exists) is not number OR not a space followed by a number, examples:
    #    (10 1 =~ /10/).should be_false
    #    (100 =~ /10/).should be_false
    if options[:personalised_default_amount].present?
      self.errors.add(:personalised_default_amount, "must be one of the personalised amounts.") unless options[:personalised_amounts] =~ /(?<!\d)#{options[:personalised_default_amount]}(?!([\d%]|\s\d))/
    end
  end

  def default_amount_is_one_of_the_suggested_amounts
    self.errors.add(:default_amount, "must be one of the suggested amounts.") unless suggested_amounts_list.include?(default_amount.to_f)
  end

  def one_frequency_option_must_be_the_default
    default_count = 0
    frequency_options.each { |frequency, option| default_count += 1 if option == "default" }
    self.errors.add(:frequency_options, "must have a single default selected.") unless default_count == 1
  end
  
  def no_personalised_amounts_with_recurring_donations
    if recurring? && eligible_for_personalised_donation_tests?
      errors.add(:use_fixed_amounts, "must be set if recurring ask") unless use_fixed_amounts?
    end
  end

  def recurring?
    ['weekly', 'monthly', 'annual'].any? { |frequency| frequency_options[frequency].present? && frequency_options[frequency] != 'hidden' }
  end

  def commence_donation_at_not_supported_by_paypal
    if !paypal_disabled?
      if commence_donation_at.present?
        self.errors.add(:commence_donation_at, "future dates not supported by PayPal.")
      end

      if custom(:form_fields).present?
        self.errors.add(:custom_fields, "are not supported by PayPal.")
      end
    end
  end

  def validate_action_attributes(params)
    # check donation_amount_in_dollars
    param_donation = params[:donation]

    custom_amount_valid = true
    custom_amount_valid = validate_amount(param_donation[:custom_amount_in_dollars]) if custom_amount_selected?(param_donation)
    if !(donation.valid? && custom_amount_valid) #note donation.valid? clears errors
      donation.errors.add(:amount_in_dollars, "is invalid") unless (custom_amount_valid || donation.errors[:amount_in_dollars].present?)
    end
    if params[:donation] && params[:donation][:payment_method] != 'credit_card'
      donation.errors.add(:base, "Invalid payment method")
      notify_user(:warning, 'Donation not processed', "Please try your donation again, or email us on help@getup.org.au and we'll be in touch.")
    end
    donation.errors.blank? && donation.user.errors.blank?
  end

  def validate_quick_donation(user)
    authenticated_for_quick_donate = !!quickdonate_cookie_for?(user)
    if donation.quick_donation? && donation.user.present? &&
      (!donation.user.enrolled_for_quick_donate? || !authenticated_for_quick_donate)
        donation.errors.add(:user, 'does not have payment details saved on this device')
        return false;
    end
    true
  end

  def validate_amount(amount)
    amount.match(/^\$?[\d]+(\.[\d]+){0,1}$/).present?
  end
end
