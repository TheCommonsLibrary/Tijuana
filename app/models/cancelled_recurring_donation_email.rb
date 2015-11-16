class CancelledRecurringDonationEmail
  
  def initialize(transaction)
    @transaction = transaction
  end
  
  def send!
    Emailer.cancelled_recurring_donation_email(@transaction).deliver
  end
  handle_asynchronously(:send!) unless Rails.env == "test"
end