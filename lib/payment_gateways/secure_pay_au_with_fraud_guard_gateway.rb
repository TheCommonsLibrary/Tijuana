class SecurePayAuWithFraudGuardGateway < ActiveMerchant::Billing::SecurePayAuGateway
  private

  def build_purchase_request(money, credit_card, options)
    super_xml = super
    
    if Setting[:use_fraud_guard] && !options[:disable_fraudguard]
      xml = Builder::XmlMarkup.new
      xml.tag! 'BuyerInfo' do
        xml.tag! 'firstName', options[:first_name] if options[:first_name]
        xml.tag! 'lastName', options[:last_name] if options[:last_name]
        xml.tag! 'zipCode', options[:zip_code] if options[:zip_code]
        xml.tag! 'town', options[:town] if options[:town]
        xml.tag! 'billingCountry', options[:billing_country] if options[:billing_country]
        xml.tag! 'deliveryCountry', options[:billing_country] if options[:billing_country]
        xml.tag! 'emailAddress', options[:email] if options[:email]
        xml.tag! 'ip', options[:ip] if options[:ip]
      end
      super_xml += xml.target!
    end
    
    super_xml
  end
  
  def securepay_url(action, request)
    use_fraudguard = request.match(/BuyerInfo/)
    if action == :purchase && use_fraudguard
      "https://#{test? ? 'test.' : ''}api.securepay.com.au/antifraud/payment"
    else
      test? ? 'https://test.api.securepay.com.au/xmlapi/payment' : live_url
    end
  end
  
  def commit(action, request)
    response = parse(ssl_post(securepay_url(action, request), build_request(action, request)))
    ActiveMerchant::Billing::Response.new(success?(response), message_from(response), response,
      :test => test?,
      :authorization => authorization_from(response)
    )
  end
  
end
