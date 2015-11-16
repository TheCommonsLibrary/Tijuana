class DonationTriggerMailer < ActionMailer::Base
  default from: 'donations@getup.org.au'
  
  EXPIRING_CARD_EMAIL = "expiring_card_email"

  def expiring_card_email(donation)
    send_email donation, "Your donation payment is expiring"
  end

  def donation_failing_email(donation)
    send_email donation, "Your donation is failing"
  end

  def donation_failing_follow_up_email(donation)
    send_email donation, "Your donation is still failing"
  end

  def cancellation_warning_email(donation)
    send_email donation, "Your donations will soon be cancelled"
  end

  private 
  def send_email(donation, subject)
    @greeting = donation.user.greeting || "Friend"
    @donation = donation
    mail(:to => donation.user.email, :from => "GetUp! Donations <donations@getup.org.au>", :subject => subject)
  end
end
