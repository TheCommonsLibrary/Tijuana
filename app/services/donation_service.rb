class DonationService
  def trigger_due_periodic_payments!(frequency, last_donated_before, becoming_due_in_the_next)
    log("START trigger_due_periodic_payments!(#{frequency}, #{last_donated_before}, #{becoming_due_in_the_next})")

    Donation.periodic_donations_processed_before(frequency, last_donated_before + becoming_due_in_the_next).each do |donation|
      trigger_overdue_periodic_payment!(donation)
    end

    log("END trigger_due_periodic_payments!(#{frequency}, #{last_donated_before}, #{becoming_due_in_the_next})")
  end

  def clear_all_out_of_date_one_off_with_triggers(time)
    log("START clear_all_out_of_date_one_off_with_triggers")
    Donation.one_off_out_of_date_donation_with_trigger_id(time).each do |donation|
      donation.trigger_id = nil
      donation.save(:validate => false)
    end
    log("END clear_all_out_of_date_one_off_with_triggers")
  end

  # Takes a payment if no successful transactions present (eg. one_off)
  #returns true if update successful
  def update_recurring_trigger!(donation, attrs = {})
    attrs = attrs.slice(:card_number, :card_type, :card_cvv, :card_expiry_month, :card_expiry_year, :amount_in_dollars, :frequency, :name_on_card)
    add_new_trigger = add_new_trigger?(donation, attrs)
    if donation.update_recurring_donation?(attrs)
      attrs_to_update = add_new_trigger ? attrs.merge(:trigger_id => "#{donation.id}_#{Time.now.to_i}") : attrs
      return update_donation!(donation, add_new_trigger, attrs_to_update)
    end
    return false
  end

  # Upgrades the recurring amount. Does not contact the gateway
  def self.upgrade_recurring!(content_module, donation, upgrade_amount_in_cents)
    donation_upgrade = DonationUpgrade.new(content_module: content_module, donation: donation,
                         original_amount_in_cents: donation.amount_in_cents, upgrade_amount_in_cents: upgrade_amount_in_cents)
    if donation_upgrade.save
      donation.amount_in_cents += upgrade_amount_in_cents
      donation.save!
    end
    donation_upgrade
  end


  def process!(donation, options={})
    return false unless donation.valid?

    if donation.recurring?
      setup_recurring_donation(donation, options)
    else
      make_one_off_donation(donation, options)
    end
  end

  def create_and_save_trigger(donation)
    donation.trigger_id = "#{donation.id}_#{donation.created_at.to_i}"
    donation.active = true
    GatewaySwitcher.store(donation)
    donation.save!
  end
  private :create_and_save_trigger

  def setup_recurring_donation(donation, options)
    if fraudulent_ip?(options[:ip])
      donation.active = false
      response = FraudulentResponse.new
      handle_payment_gateway_response(donation, response, options[:ip])
    else
      if donation.quick_donation?
        setup_recurring_quick_donate(donation, options)
      else
        setup_recurring_donation_with_trigger(donation, options)
      end
    end
  end

  def setup_recurring_quick_donate(donation, options)
    populate_quick_donation(donation)
    if !donation.content_module.for_a_future_recurring_payment?
      trigger_recurring_payment!(donation, options)
    else
      donation.update_attributes!(:last_donated_at => donation.get_future_last_donated_at)
      true
    end
  end

  def setup_recurring_donation_with_trigger(donation, options)
    if !donation.content_module.for_a_future_recurring_payment?
      response = pay_and_create_trigger(donation, options)
      handle_payment_gateway_response(donation, response, options[:ip], options[:shared_connection], options[:acquisition_source])
    else
      create_and_save_trigger(donation)
      donation.update_attributes!(:last_donated_at => donation.get_future_last_donated_at)
      true
    end
  end

  def trigger_recurring_payment!(donation, options={})
    log("trigger_recurring_payment", donation)
    response = GatewaySwitcher.purchase_with_trigger(donation, order_id: donation.id)
    handle_payment_gateway_response(donation, response, options[:ip], options[:shared_connection], options[:acquisition_source])
  end

  def make_one_off_donation(donation, options)
    if !donation.quick_donation?
      if fraudulent_ip?(options[:ip])
        response = FraudulentResponse.new
      else
        response = pay_and_create_trigger(donation, options)
      end
    else
      log("trigger quickdonate for user id #{donation.user.id}", donation)
      populate_quick_donation(donation)
      response = GatewaySwitcher.purchase_with_trigger(donation, order_id: donation.id)
    end
    handle_payment_gateway_response(donation, response, options[:ip], options[:shared_connection], options[:acquisition_source])
  end

  def trigger_overdue_periodic_payment!(donation, options={})
    log("trigger_periodic_payment!", donation)
    raise "Donation #{id} is not active and cannot be triggered." unless donation.active?
    response = nil
    donation.with_claim_for_processing do
      response = GatewaySwitcher.purchase_with_trigger(donation, order_id: donation.id)
    end
    handle_payment_gateway_response(donation, response, options[:ip])
  end

  def refund(amount_in_cents, transaction)
    amount_in_cents = amount_in_cents.to_i
    check_valid_refund(amount_in_cents, transaction)
    response = GatewaySwitcher.refund(transaction, amount_in_cents)
    refunded_transaction = GatewaySwitcher.create_refund_transaction transaction, response
    raise Transaction::RefundFailedError.new(response.message) unless response.success?

    transaction.refunded = true
    transaction.save!
    RefundReceiptEmail.new(refunded_transaction).send!
  end

private
  def check_valid_refund(amount_in_cents, transaction)
    if amount_in_cents < 1 || amount_in_cents > transaction.amount_in_cents
      raise Transaction::RefundFailedError.new("Refunded amount must be positive and <= the original payment.")
    end
    raise Transaction::RefundFailedError.new("Transaction has already been refunded.") if transaction.refunded?
    raise Transaction::RefundFailedError.new("Cannot refund a failed transaction.") if !transaction.successful?
  end

  def populate_quick_donation(donation)
    donation.copy_credit_card_details!(Donation.find_by_trigger_id(donation.user.quick_donate_trigger_id))
  end

  def pay_and_create_trigger(donation, options)
    response = nil

    begin
      response = gateway_purchase(donation, options[:ip])
    ensure
      if Setting[:use_cc_logging]
        if response.nil? || !response.success?
          FailedDonation.create!(credit_card: donation.credit_card.to_yaml, donation_id: donation.id)
        end
      end
    end

    create_and_save_trigger(donation) if response.success?
    response
  end

  def gateway_purchase(donation, ip)
    GatewaySwitcher.purchase_with_credit_card(donation, ip)
  end

  def fraudulent_ip?(ip)
    return !BlockedIp.find_by_ip_address(ip).nil?
  end

  def updating_quick_donate?(donation)
    donation.trigger_id == donation.user.quick_donate_trigger_id
  end

  # Takes a payment if no successful transactions present (eg. one_off)
  def update_donation!(donation, add_new_trigger, attrs)
    updating_quick_donate = updating_quick_donate?(donation)
    donation.updating = true
    donation.update_recurring_donation(attrs)
    if add_new_trigger
      trigger_success = add_trigger(donation)
      if trigger_success
        donation.transaction do
          donation.save!
          donation.user.update_attributes!({:quick_donate_trigger_id => attrs[:trigger_id]}) if updating_quick_donate
        end
        payment_succeeded = trigger_recurring_payment!(donation) if donation.transactions.size == 0 || !donation.transactions.max_by { |t| t.updated_at }.successful?
        if payment_succeeded
          donation.active = true
          donation.cancelled_at = nil
          donation.cancel_reason = nil
          donation.save!
        end
      end
      return trigger_success
    end
    return true
  end

  def add_trigger(donation)
    response = GatewaySwitcher.store(donation)
    if response.success?
      donation.last_tried_at = nil
      donation.save!
      return true
    end

    donation.errors.add(donation.payment_method.to_sym, "payment failed - #{response.message}")
    return false
  end

  def add_new_trigger?(donation, attrs)
    (attrs[:card_number].blank? ? false : attrs[:card_number].last(4) != donation.card_last_four_digits) ||
        (attrs[:card_type].blank? ? false : attrs[:card_type] != donation.card_type) ||
        (!attrs[:card_cvv].blank?)
  end

  def notify_donation_of_payment_gateway_response(donation, response)
    if response.success?
      donation.on_successful_payment
    else
      donation.on_failed_payment(response.message)
    end
  rescue => e
    ExceptionNotifier.notify_exception(e).deliver
  end
  private :notify_donation_of_payment_gateway_response

  def handle_payment_gateway_response(donation, response, ip_address, shared_connection=nil, acquisition_source=nil)
    notify_donation_of_payment_gateway_response(donation, response)
    txn = record_transaction_register_uae_and_connection(donation, response, ip_address, shared_connection, acquisition_source)
    DonationReceiptEmail.new(txn).send! if send_receipt?(txn, donation)
    return txn.successful?
  end

  def send_receipt?(transaction, donation)
    t = Transaction.where(:donation_id => donation.id, :successful => true).count
    transaction.successful? && t == 1
  end
  private :send_receipt?

  def record_transaction_register_uae_and_connection(donation, response, ip_address, shared_connection, acquisition_source)
    transaction = create_purchase_transaction donation, response, ip_address
    if transaction.successful?
      ContentModule.create_uae_and_shared_connection(donation, transaction, shared_connection, acquisition_source)
    end
    transaction
  end
  private :record_transaction_register_uae_and_connection

  def create_purchase_transaction(donation, response, ip_address)
    if response.kind_of? FraudulentResponse
      response.create_fraudulent_transaction donation
    else
      GatewaySwitcher.create_purchase_transaction donation, response, ip_address
    end
  end

  def log(msg, donation=nil)
    if donation.nil?
      Rails.logger.info {"DONATION_DEBUG #class: " + msg }
    else
      Rails.logger.info {"DONATION_DEBUG Donation##{donation.id}: " + msg }
    end
  end
end
