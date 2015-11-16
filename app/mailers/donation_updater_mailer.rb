class DonationUpdaterMailer < ActionMailer::Base
  default from: 'donations@getup.org.au'

  def donation_update_email(user, old_amount_in_dollars, old_frequency, new_amount_in_dollars, new_frequency)
    @user = user
    @upgrade = upgrade?(old_amount_in_dollars, old_frequency, new_amount_in_dollars, new_frequency)
    @old_amount_in_dollars = old_amount_in_dollars
    @old_frequency = old_frequency
    @new_amount_in_dollars = new_amount_in_dollars.to_f
    @new_frequency = new_frequency
    @subject = @upgrade ? "Thanks for increasing your Crew support" : "Your Crew donation has been updated"
    mail(:to => @user.email, :from => "GetUp! Donations <donations@getup.org.au>", :subject => @subject)
  end

private

  def upgrade?(old_amount_in_dollars, old_frequency, new_amount_in_dollars, new_frequency)
    donation_frequency_multiplier = {
      'weekly' => 52,
      'monthly' => 12,
      'annual' => 1,
      'one_off' => 1
    }
    old_amount_total_value = old_amount_in_dollars * donation_frequency_multiplier[old_frequency]
    new_amount_total_value = new_amount_in_dollars.to_f * donation_frequency_multiplier[new_frequency]
    new_amount_total_value > old_amount_total_value
  end

end
