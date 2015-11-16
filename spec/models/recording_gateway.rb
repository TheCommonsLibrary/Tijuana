class RecordingGateway < ActiveMerchant::Billing::BogusGateway
  attr_accessor :purchase_attributes, :purchased, :stored

  def initialize
    @purchased = false
    @purchase_attributes = Array.new(3)
    @service = DonationService.new
    super()
  end

  def store(creditcard, options = {})
    @purchase_attributes = [options[:amount], creditcard.instance_values, options.except(:amount)]
    @stored = true
    super(creditcard, options)
  end

  def purchase(amount_in_cents, credit_card_or_stored_id, options = {})
    @purchase_attributes[0] = amount_in_cents
    @purchase_attributes[2] = options.except(:amount)
    @purchased = true
    super(amount_in_cents, credit_card_or_stored_id, options)
  end
end
