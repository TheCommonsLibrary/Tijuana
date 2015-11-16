class FraudulentResponse
  def success?
    false
  end

  def message
    'external payment error'
  end

  def create_fraudulent_transaction(donation)
    Transaction.create!(
      :donation => donation,
      :message => message,
      :successful => success?
    )
  end
end
