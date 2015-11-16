class DonationTriggerService
  def fire_trigger
    trigger_expiring_card
    trigger_failing
    cancel
  end

  def trigger_expiring_card
    next_month = Date.today.end_of_month + 1
    this_and_next_month_expiries = {
      this_month: Date.today.month,
      this_month_year: Date.today.year,
      next_month: next_month.month,
      next_month_year: next_month.year
    }

    expiring_donations = Donation.active.recurring
      .where(
        '(card_expiry_month = :this_month and card_expiry_year = :this_month_year) or ' +
        '(card_expiry_month = :next_month and card_expiry_year = :next_month_year)',
        this_and_next_month_expiries
      )
      .where("card_type is null or card_type not in ('visa', 'mastercard')")
    expiring_donations.find_each(batch_size: 10_000) do |donation|
      next if probably_fraud? donation
      expiry_email = last_failure_email_of(donation, :expiring_card_email)
      if expiry_email.nil? || Time.now - expiry_email.sent_date >= 1.month
        send_and_record_email(donation, :expiring_card_email)
      end
    end
  end

  def trigger_failing
    get_failed_donations.find_each(batch_size: 10_000) do |donation|
      next if probably_fraud? donation
      dunning_state, how_long_in_state = dunning_state(donation)
      
      case dunning_state
      when :first_action
        if can_send_email?(donation, :donation_failing_email, how_long_in_state)
          send_and_record_email(donation, :donation_failing_email)
        end
      when :second_action
        if can_send_email?(donation, :donation_failing_follow_up_email, how_long_in_state)
          send_and_record_email(donation, :donation_failing_follow_up_email)
          flag_donation(donation, "Sent failing follow up email")
        end
      when :third_action
        if can_send_email?(donation, :cancellation_warning_email, how_long_in_state)
          send_and_record_email(donation, :cancellation_warning_email)
          flag_donation(donation, "Sent cancellation warning email")
        end
      end
    end
  end

  def cancel
    cancellation_window = 2.months
    Donation.recurring.active
      .where('last_tried_at > last_donated_at and last_tried_at < ?', cancellation_window.ago)
      .find_each{|donation| donation.cancel_recurring!('automatic', donation.last_tried_at + cancellation_window) }
  end
  
  def dunning_state(donation)
    last_failure_email = last_failure_email donation
    last_failure_email = nil if donation.has_successful_transaction_since?(last_failure_email.sent_date) if last_failure_email
    
    case last_failure_email.try(:key)
    when nil then [:first_action, nil]
    when "donation_failing_email" then [:second_action, Time.now - last_failure_email.sent_date]
    when "donation_failing_follow_up_email" then [:third_action, Time.now - last_failure_email.sent_date]
    else nil
    end
  end
  
  def last_failure_email(donation)
    last_failure_email_of(donation, FAILURE_EMAILS)
  end

  private

  FAILURE_EMAILS = [
    :donation_failing_email,
    :donation_failing_follow_up_email,
    :cancellation_warning_email
  ]

  def probably_fraud?(donation)
    !donation.has_successful_transaction?
  end

  def can_send_email?(donation, template, how_long_in_state = nil)
    return true if how_long_in_state == nil
    how_long_in_state >= 1.month && !donation.has_successful_transaction_since?(Time.now - how_long_in_state)
  end

  def last_failure_email_of(donation, template)
    SentTriggerEmail.where(key: template, user_id: donation.user.id, triggered_by_id: donation.id, triggered_by_type: donation.class.name)
                    .order("sent_date desc").first
  end

  def get_failed_donations
    Donation.where(id: weekly_consecutive_failed_donation_ids + monthly_annually_failed_donation_ids)
  end

  def send_and_record_email(donation, template)
    DonationTriggerMailer.send(template, donation).deliver
    SentTriggerEmail.create(:user_id => donation.user.id, :sent_date => Date.today, :key => template.to_s, triggered_by: donation)
  end

  def flag_donation(donation, reason)
    Donation.where(id: donation.id).update_all([
          "flagged_since = ?,
          flagged_because = ?,
          dismissed_at = null",
          Time.now, reason])
  end

  def weekly_consecutive_failed_donation_ids
    failed_donation_ids_query = <<-SQL
      select d.id
      from transactions t
      join donations d
        on t.donation_id = d.id
        and d.active = 1
        and d.frequency = 'weekly'
      where cast(response_code as signed) < 110
      group by d.id
      having group_concat(t.successful order by t.created_at desc) like '0,0%'
    SQL
    Donation.connection.select_values(failed_donation_ids_query)
  end

  def monthly_annually_failed_donation_ids
    failed_donation_ids_query = <<-SQL
      select d.id
      from transactions t
      join donations d
        on t.donation_id = d.id
        and d.active = 1
        and d.frequency in ('monthly', 'annual')
      where cast(response_code as signed) < 110
      group by d.id
      having group_concat(t.successful order by t.created_at desc) like '0%'
    SQL
    Donation.connection.select_values(failed_donation_ids_query)
  end
end
