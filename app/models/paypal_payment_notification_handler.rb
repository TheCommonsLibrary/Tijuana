require 'bigdecimal'
require 'bigdecimal/util'

class PaypalPaymentNotificationError < StandardError; end

class PaypalPaymentNotificationHandler

  CR_STATUSES = %w(Completed Created Processed Canceled_Reversal)
  DR_STATUSES = %w(Refunded Reversed)

  include VanityHelper

  def initialize(params, raw_post)
    @params = params
    @raw_post = raw_post
  end

  def verify_and_handle_ipn
    if verified_ipn_request?
      if receiver_email.present? && !receiver_email.match(AppConstants.paypal_receiver_domain)
        # This either indicates a bug in our PayPal setup, or that someone is sending us valid IPN messages that belong to someone else
        raise PaypalPaymentNotificationError, "Incorrect receiver email for IPN #{@params}"
      end
      handle_ipn
    end
  end

  handle_asynchronously :verify_and_handle_ipn

  def handle_ipn
    if chargeback?
      Rails.logger.info "PaypalPaymentNotificationHandler ignoring chargeback: #{@params}"
    elsif recordable_transaction_message?
      record_transaction unless transaction_id.blank?
    else
      case transaction_type
        when 'subscr_signup'
          handle_subscription_signup
        when 'subscr_modify', 'recurring_payment_profile_cancel', 'new_case'
          Rails.logger.info "PaypalPaymentNotificationHandler ignoring #{@params}"
        when /subscr_cancel|subscr_eot/
          handle_subscription_cancel
        else
          raise PaypalPaymentNotificationError, "Unhandled transaction_type #{transaction_type}"
      end
    end
  end

  private

  def chargeback?
    case_type == 'chargeback'
  end

  def recordable_transaction_message?
    !%w{subscr_signup subscr_modify subscr_cancel subscr_eot recurring_payment_profile_cancel new_case}.include?(transaction_type)
  end

  def cancelled?
    payment_status.try(:start_with?, 'Canceled_')
  end

  def record_transaction
    user = create_or_update_user
    if cancelled?
      cancel_transaction
    else
      unless check_for_duplicates == :duplicate_transaction
        donation = find_or_create_donation(user)
        transaction = create_transaction(donation)
        token = id && id.split("-").third
        tracking_token = TrackingTokenLookup.new(token)
        uae = create_user_activity_event_on_successful_transaction(donation, transaction, tracking_token)
        create_shared_connection_on_initial_donation donation, uae, tracking_token
        record_vanity_conversion user, donation
        DonationReceiptEmail.new(transaction).send! if send_receipt?(transaction, donation)
      end
    end
  end

  def send_receipt?(transaction, donation)
    t = Transaction.where(:donation_id => donation.id, :successful => true).count
    transaction.successful? && t == 1
  end

  def handle_subscription_signup
    user = create_or_update_user
    donation = find_or_create_donation(user)
    donation.update_attributes!(frequency: subscription_period, amount_in_cents: PaypalPaymentNotificationHandler.currency_to_cents(subscription_amount))
  end

  def handle_subscription_cancel
    donation = Donation.find_by_paypal_subscr_id(subscription_id)
    donation.disable_recurring_trigger!
  end

  def find_or_create_donation(user)
    begin
      parent_transaction.try(:donation) || find_subscription_donation || create_donation(user, transaction_amount || subscription_amount || amount)
    rescue ActiveRecord::RecordNotUnique
      # There is a race condition between paypal 'subscr_signup' and the first 'subscr_payment' message. The database prevents creation of
      # duplicate donation records with a unique index on paypal_subscr_id, but the message that fails to create the donation
      # must find the one created by the other thread:
      Rails.logger.debug { "PaypalPaymentNotificationHandler failed to create donation, find again" }
      find_subscription_donation
    end
  end

  def find_subscription_donation
    Donation.find_by_paypal_subscr_id(subscription_id) if subscription_id.present?
  end

  def cancel_transaction
    transaction = Transaction.find_by_txn_ref(transaction_id)
    if transaction.present?
      transaction.update_attributes(
          successful: false,
          response_code: payment_status,
          status_reason: reason_code
      )
    else
      Rails.logger.warn { "PaypalPaymentNotificationHandler received cancellation for transaction that we have no record of: #{@params}" }
    end
  end

  def create_transaction(donation)
    # we store all transactions for future reference, even if they don't have
    # a paypal transaction id and we don't process them further

    transaction = Transaction.create(
        donation: donation,
        amount_in_cents: PaypalPaymentNotificationHandler.currency_to_cents(transaction_amount, donation.amount_in_cents),
        txn_ref: transaction_id,
        refund_of_id: refund_status? ? parent_transaction.try(:id) : nil,
        currency: currency,
        fee_in_cents: PaypalPaymentNotificationHandler.currency_to_cents(transaction_fee),
        status_reason: pending_reason || reason_code,
        response_code: payment_status,
        successful: (CR_STATUSES + DR_STATUSES).include?(payment_status),
        settled_on: payment_date.present? ?  Time.strptime(payment_date, "%H:%M:%S %b %d, %Y %Z").in_time_zone.to_date : nil, #will be recorded in UTC time
        message: transaction_type.try(:humanize)
    )

    parent_transaction.update_attributes(refunded: true) if parent_transaction.present? && refund_status?

    transaction
  end

  def create_donation(user, amount)
    page_id, ask_id, token = id.split("-")
    trackingTokenLookup = TrackingTokenLookup.new(token)
    page = Page.find(page_id)
    ask = ContentModule.find(ask_id)
    raise PaypalPaymentNotificationError, "Could not identify DonationModule" unless ask.donatable?
    Donation.create!(
        user: user,
        page: page,
        email: trackingTokenLookup.email,
        content_module: ask,
        name_on_card: payer_email,
        payment_method: 'paypal',
        frequency: frequency,
        amount_in_cents: PaypalPaymentNotificationHandler.currency_to_cents(amount),
        paypal_subscr_id: subscription_id
    )
  end

  def create_user_activity_event_on_successful_transaction(donation, transaction, tracking_token)
    transaction.successful? ? UserActivityEvent.action_taken!(donation.user, donation.page, donation.content_module, transaction, donation.email, nil, tracking_token.acquisition_source) : nil
  end

  def create_shared_connection_on_initial_donation(donation, uae, trackingTokenLookup)
    ExceptionNotifier.rescue_and_mail_tech do
      if donation.transactions.count == 1 && uae
        shared_connection = SharedConnections.new(
          originator: trackingTokenLookup.user,
          action_taker: donation.user,
          user_activity_event: uae
        )

        shared_connection.save! if shared_connection.valid?
      end
    end
  end

  def record_vanity_conversion(user, donation)
    return unless id
    _, _, _, vanity_id, experiment_ids = id.split("-")
    track_with_user :money, donation.amount_in_cents, user, donation, vanity_id, experiment_ids if vanity_id
  end

  def create_or_update_user
    user = find_or_create_user
    update_missing_user_details!(user)
    user
  end

  def find_or_create_user
    user = User.new(email: payer_email)
    user.save_with_source 'paypal', validate: false
    UserMailer.welcome_to_getup(user)
    user
  rescue ActiveRecord::RecordNotUnique
    User.find_by_email payer_email
  end

  def update_missing_user_details!(user)
    # source of trust is our current DB
    user.first_name ||= first_name
    user.last_name ||= last_name

    if postcode.present? && (user.postcode_number.blank? || user.postcode_number == postcode)
      user.postcode_number ||= postcode
      user.street_address ||= address_street
      user.suburb ||= address_city
    end

    user.save!
  end

  def check_for_duplicates
    existing_transactions = Transaction.where(txn_ref: transaction_id)
    if existing_transactions.size > 0
      existing_transaction = existing_transactions.first

      if (existing_transaction.amount_in_cents == PaypalPaymentNotificationHandler.currency_to_cents(transaction_amount) &&
          existing_transaction.message == transaction_type.try(:humanize))
        Rails.logger.info "PaypalPaymentNotificationHandler duplicate transaction with same information: #{@params}"
        return :duplicate_transaction
      else
        raise PaypalPaymentNotificationError, "Duplicate transaction id for IPN #{@params}"
      end
    end
  end

  def parent_transaction
    Transaction.find_by_txn_ref(parent_transaction_id) if parent_transaction_id.present?
  end

  def subscription_period
    case @params['period3']
      when /1 W/
        'weekly'
      when /1 M/
        'monthly'
      when /1 Y/
        'annual'
      else
        raise PaypalPaymentNotificationError, "Unknown subscription period '#{@params['period3']}'"
    end
  end

  def refund_status?
    DR_STATUSES.include? payment_status
  end

  def self.currency_to_cents(string_val, default = 0)
    return default if string_val.blank?
    (string_val.to_d * 100).to_i
  end

#see http://stackoverflow.com/questions/14316426/is-there-a-paypal-ipn-code-sample-for-ruby-on-rails
  def verified_ipn_request?
    uri = URI.parse("#{AppConstants.paypal_post_url}?cmd=_notify-validate")
    http = Net::HTTP.new(uri.host, uri.port)
    http.open_timeout = 60
    http.read_timeout = 60
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    http.use_ssl = true
    response = http.post(uri.request_uri, @raw_post,'Content-Length' => "#{@raw_post.size}")
    if response.body == "VERIFIED"
      return true
    else
      Rails.logger.warn "PaypalPaymentNotificationHandler IPN verification failed on #{@raw_post}"
      return false
    end
  end

  def case_type
    @params['case_type']
  end

  def id
    @params['id']
  end

  def first_name
    @params["first_name"]
  end

  def last_name
    @params["last_name"]
  end

  def payer_email
    @params["payer_email"]
  end

  def address_street
    @params["address_street"]
  end

  def address_city
    @params["address_city"]
  end

  def postcode
    @params["address_zip"]
  end

  def subscription_amount
    @params["mc_amount3"]
  end

  def subscription_id
    @params['subscr_id'] || @params['recurring_payment_id']
  end

  def transaction_type
    @params['txn_type']
  end

  def parent_transaction_id
    @params['parent_txn_id']
  end

  def transaction_id
    @params["txn_id"]
  end

  def receiver_email
    @params['receiver_email']
  end

  def transaction_amount
    @params["mc_gross"]
  end

  def transaction_fee
    @params["mc_fee"]
  end

  def currency
    @params["mc_currency"]
  end

  def payment_status
    @params["payment_status"]
  end

  def pending_reason
    @params["pending_reason"]
  end

  def payment_date
    @params["payment_date"]
  end

  def amount
    @params["amount"]
  end

  def reason_code
    @params["reason_code"]
  end

  def frequency
    period = @params["payment_cycle"] || 'one_off'
    return "annual" if period == "Yearly"
    period.downcase
  end
end
