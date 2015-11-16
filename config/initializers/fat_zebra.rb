module ActiveMerchant #:nodoc:
  module Billing #:nodoc:
    class FatZebraGateway < Gateway
      alias_method :store_without_options, :store
      
      def store(creditcard, options = {})
        store_without_options creditcard
      end
      
      alias_method :refund_without_options, :refund
      
      def refund(money, txn_id, options = {})
        refund_without_options money, txn_id, options[:reference]
      end
    end
  end
end