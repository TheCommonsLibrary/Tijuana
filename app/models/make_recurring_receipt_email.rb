class MakeRecurringReceiptEmail

  def initialize(donation)
    @donation = donation
  end

  def send!
    Emailer.make_recurring_receipt_email(@donation).deliver
  end
  handle_asynchronously(:send!) unless Rails.env == "test"
end
