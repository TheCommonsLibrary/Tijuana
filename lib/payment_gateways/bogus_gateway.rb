module ActiveMerchant
  module Billing
    class BogusGateway < Gateway
      MAGIC_CENTS_TO_FORCE_FAILURE = 123
      MAGIC_CENTS_TO_FORCE_DELAY = 5366
      MAGIC_CENTS_TO_FORCE_EXCEPTION = 5367

      def store(creditcard, options = {})
        @creditcard = creditcard # Store for later triggering
        falsify_response(creditcard, nil)
      end

      def purchase_count= arg
        @purchase_count = arg
      end
      def purchase_count
        @purchase_count ||= 0
      end

      def purchase(amount, credit_card_or_stored_id, options = {})
        self.purchase_count += 1

        if credit_card_or_stored_id.respond_to?(:number)
          @creditcard = credit_card_or_stored_id
        else
          @creditcard ||= ActiveMerchant::Billing::CreditCard.new(
            :brand => "visa",
            :first_name => "Recurring payments do",
            :last_name => "not need a card in prod",
            :number => "1",
            :month => "12",
            :year => "2099",
            :verification_value => "123"
          )
        end

        sleep(1) if amount == MAGIC_CENTS_TO_FORCE_DELAY
        raise ActiveMerchant::ConnectionError.new("FORCED EXCEPTION FOR TEST", Exception.new) if amount == MAGIC_CENTS_TO_FORCE_EXCEPTION
        return Response.new(false, FAILURE_MESSAGE, {:amount => amount, :error => FAILURE_MESSAGE}, :test => true) if amount == MAGIC_CENTS_TO_FORCE_FAILURE
        falsify_response(@creditcard, amount)
      end

      def refund(amount, ref, options={})
        success = amount != MAGIC_CENTS_TO_FORCE_FAILURE
        Response.new(success, "Bogus Gateway: #{success ? 'Approved' : 'Failed'} Refund", {:amount =>amount, :txn_type => "4"}, :test => true)
      end
private

      def falsify_response(creditcard, money)
        case creditcard.number
          when '1', '4111111111111111', '41111'
            Response.new(true, SUCCESS_MESSAGE, {:amount => money}, :test => true)
          when '2'
            Response.new(false, FAILURE_MESSAGE, {:amount => money, :error => FAILURE_MESSAGE}, :test => true)
          else
            raise Error, ERROR_MESSAGE
        end
      end

      def build_request(action_type, request)
        request
      end
    end
  end
end
