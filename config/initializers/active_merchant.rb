require 'payment_gateways/secure_pay_au_with_fraud_guard_gateway'

ActiveMerchant::Billing::Gateway.default_currency = "AUD"

# default timeouts are 60, up this for slow secure pay
ActiveMerchant::Billing::Gateway.open_timeout = 120
ActiveMerchant::Billing::Gateway.read_timeout = 120

require 'payment_gateways/bogus_gateway' if Rails.env.development? or Rails.env.test?
