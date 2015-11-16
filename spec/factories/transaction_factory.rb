FactoryGirl.define do
  factory(:transaction) do |t|
    t.donation        { create(:donation) }
    t.amount_in_cents { 1000 }
    t.refunded        { false }
    t.successful      { true }
    t.created_at      { Time.now }
    t.gateway_name    { 'SecurePay' }
    t.response_code   { '00' }
    t.message         { 'Approved' }
  end

  factory(:failed_transaction, parent: :transaction) do |t|
    t.successful      { false }
    t.response_code   { '54' }
    t.message         { 'Expired Card' }
  end

  factory(:failed_system_transaction, parent: :failed_transaction) do |t|
    # codes over 109 represent non-user failures, seemingly
    # see https://www.securepay.com.au/wp-content/uploads/2017/06/SecurePay_Response_Codes.pdf
    t.response_code   { '110' }
    t.message         { 'Unable to connect to server' }
  end

end
