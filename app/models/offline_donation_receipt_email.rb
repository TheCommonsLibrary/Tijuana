class OfflineDonationReceiptEmail < DonationReceiptEmail
  def send!
    txns = prepare_donation_transactions

    txns.each_key do |donation|
      trans = txns[donation]
      Emailer.offline_donation_receipt_email(donation, trans).deliver
    end
  end

  handle_asynchronously(:send!) unless Rails.env == "test"
end
