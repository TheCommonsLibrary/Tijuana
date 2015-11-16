class TransactionsTable
  include ReportTable
    
  def self.columns
    ["#", "Txn Date", "Gateway Name", "Name on Card", "Payment Method", "Frequency", "Txn Status", "Bank Ref", "Txn Ref", "Amount", "Card Last 4 Digits", "Campaign", "IP Address", 'Visa/Mastercard recurring flag']
  end
  
  def initialize(transactions)
    @transactions = transactions.to_a
    @transactions.sort_by! { |txn| txn.created_at  }.reverse!
  end
  
  def rows   
    @transactions.inject([]) { |rows, txn| rows << row_for(txn); rows }
  end
  
  def rows_with_ids
    @transactions.inject([]) { |rows_with_ids, txn| rows_with_ids << [row_for(txn), txn.respond_to?(:txn_id) ? txn.txn_id : txn.id, txn.donation.id]; rows_with_ids }
  end
  
  
  private
  
  def row_for(txn)
    if txn.respond_to?(:txn_id)
      payment_method = txn.payment_method == "credit_card" ? txn.card_type : txn.payment_method
      [
        txn.txn_id,
        txn.created_at.to_date,
        txn.gateway_name,
        txn.name_on_card,
        (payment_method || "").titlecase,
        txn.donation.frequency.titlecase,
        txn.successful? ? "Successful" : "Failed",
        txn.bank_ref,
        txn.txn_ref,
        number_to_currency(txn.amount_in_dollars),
        txn.donation.card_last_four_digits,
        txn.campaign_name,
        txn.ip_address,
        txn.recurring_flag
      ]
    else
      donation = txn.donation
      campaign = donation.try(:page).try(:page_sequence).try(:campaign)
      payment_method = donation.payment_method == "credit_card" ? donation.card_type : donation.payment_method
      [
          txn.id,
          txn.created_at.to_date,
          txn.gateway_name,
          txn.donation.name_on_card,
          (payment_method || "").titlecase,
          txn.donation.frequency.titlecase,
          txn.successful? ? "Successful" : "Failed",
          txn.bank_ref,
          txn.txn_ref,
          number_to_currency(txn.amount_in_dollars),
          txn.donation.card_last_four_digits,
          campaign ? campaign.name : nil,
          txn.ip_address,
          txn.recurring_flag
      ]
    end
  end
end
