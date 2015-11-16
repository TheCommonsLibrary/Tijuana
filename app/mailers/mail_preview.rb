class MailPreview < MailView
  def one_off_receipt_email
    user = User.new :email => 'matt@member.com', :is_member => true, :is_agra_member => true, :first_name => 'Matt', :last_name => 'Member'
    donation = Donation.new :user => user, :amount_in_cents => 5000, :frequency => 'one_off'
    transaction = Transaction.new :donation => donation, :amount_in_cents => donation.amount_in_cents, :refunded => false, :successful => true, :bank_ref => 123, :created_at => Time.now
    Emailer.one_off_receipt_email donation, [transaction]
  end

  def offline_donation_receipt_email
    user = User.new :email => 'matt@member.com', :is_member => true, :is_agra_member => true, :first_name => 'Matt', :last_name => 'Member'
    donation = Donation.new :user => user, :amount_in_cents => 5000, :frequency => 'one_off', :payment_method => 'eftpos'
    transaction = Transaction.new :donation => donation, :amount_in_cents => donation.amount_in_cents, :refunded => false, :successful => true, :bank_ref => 123, :created_at => Time.now
    Emailer.offline_donation_receipt_email donation, [transaction]
  end

  def donation_update_email
    user = User.new :email => 'matt@member.com', :is_member => true, :is_agra_member => true, :first_name => 'Matt', :last_name => 'Member'
    old_amount_in_dollars = 20
    old_frequency = 'one_off'
    new_amount_in_dollars = 50
    new_frequency = 'weekly'
    DonationUpdaterMailer.donation_update_email user, old_amount_in_dollars, old_frequency, new_amount_in_dollars, new_frequency
  end

  def cancelled_recurring_donation_email
    user = User.new :email => 'matt@member.com', :is_member => true, :is_agra_member => true, :first_name => 'Matt', :last_name => 'Member'
    donation = Donation.new :user => user, :amount_in_cents => 5000, :frequency => 'weekly'
    Emailer.cancelled_recurring_donation_email donation
  end

  def reset_password_instructions
    user = User.new :email => 'matt@admin.com', :reset_password_token => "abcd1234!@#", :is_member => true, :is_agra_member => true, :is_admin => true, :first_name => 'Matt', :last_name => 'admin'
    PasswordMailer.reset_password_instructions user
  end

  def expiring_card_email
    user = User.new :email => 'matt@admin.com',:is_member => true, :first_name => 'Matt', :last_name => 'admin'
    donation = Donation.new :user => user, :amount_in_cents => 5000, :frequency => 'weekly'
    donation.id = 1

    DonationTriggerMailer.expiring_card_email donation
  end

  def donation_failing_email
    user = User.new :email => 'matt@admin.com',:first_name => 'Matt', :last_name => 'admin'
    donation = Donation.new :user => user, :amount_in_cents => 5000, :frequency => 'weekly'
    donation.id = 1

    DonationTriggerMailer.donation_failing_email donation
  end

  def donation_failing_follow_up_email
    user = User.new :email => 'matt@admin.com',:first_name => 'Matt', :last_name => 'admin'
    donation = Donation.new :user => user, :amount_in_cents => 5000, :frequency => 'weekly'
    donation.id = 1

    DonationTriggerMailer.donation_failing_follow_up_email donation
  end

  def cancellation_warning_email
    user = User.new :email => 'matt@admin.com',:first_name => 'Matt', :last_name => 'admin'
    donation = Donation.new :user => user, :amount_in_cents => 5000, :frequency => 'weekly'
    donation.id = 1

    DonationTriggerMailer.cancellation_warning_email donation
  end
end
