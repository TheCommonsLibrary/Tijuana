class DonationReceiptEmail

  def initialize(transaction)
    @transactions = [transaction].flatten
  end

  def send!
    txns = prepare_donation_transactions

    txns.each_key do |donation|
      trans = txns[donation]
      if (donation.recurring?)
        Emailer.recurring_receipt_email(donation, trans).deliver
      else
        Emailer.one_off_receipt_email(donation, trans).deliver
      end
    end
  end

  handle_asynchronously(:send!) unless Rails.env == "test"

  private

  def prepare_donation_transactions
    txns = {}

    @transactions.each do |transaction|
      begin
        txns[transaction.donation].push transaction
      rescue
        txns[transaction.donation] = [transaction]
      end
    end

    txns
  end
end
