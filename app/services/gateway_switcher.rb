class GatewaySwitcher
  class << self
    def purchase_with_credit_card(donation, ip)
      purchase donation, ip, false
    end

    def purchase_with_trigger(donation, ip)
      purchase donation, ip, true
    end

    def store(donation)
      random_gateway_mapper.gateway.store(donation.credit_card, order_id: donation.id, billing_id: donation.trigger_id, amount: donation.amount_in_cents)
    end

    def refund(transaction, amount_in_cents)
      mapper = find_gateway_mapper(transaction.gateway_name)
      reference = mapper.reference(transaction)
      mapper.gateway.refund amount_in_cents, reference, :reference => transaction.txn_ref
    end
    
    def create_purchase_transaction(donation, response, ip_address)
      find_gateway_mapper(response.params["gateway_name"]).create_purchase_transaction donation, response, ip_address
    end
    
    def create_refund_transaction(purchase_transaction, response)
      find_gateway_mapper(purchase_transaction.gateway_name).create_refund_transaction purchase_transaction, response
    end
    
  private

    def find_gateway_mapper(gateway_name)
      [GatewaySwitcher.gateway1_mapper, GatewaySwitcher.gateway2_mapper].detect { |m| m.name == gateway_name }
    end
    
    def random_gateway_mapper
      random_percentage <= Setting.gateway1_percentage ? GatewaySwitcher.gateway1_mapper : GatewaySwitcher.gateway2_mapper
    end
    
    def purchase(donation, ip, with_trigger)
      mapper = random_gateway_mapper
      credit_card_or_trigger = with_trigger ? donation.trigger_id : donation.credit_card
      options = mapper.build_purchase_options(donation, ip, with_trigger)
      response = mapper.gateway.purchase donation.amount_in_cents, credit_card_or_trigger, options
      response.params["gateway_name"] = mapper.name
      response
    end

    def random_percentage
      Kernel.rand(1..100)
    end
  end
end
