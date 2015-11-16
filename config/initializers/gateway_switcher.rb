require "gateway_switcher"

ActiveMerchant::Billing::Base.mode = :test unless Rails.env.production?

# here to avoid gateway_switcher.rb being reloaded in dev and clearing attributes
class GatewaySwitcher
  class << self
    attr_accessor :gateway1_mapper, :gateway2_mapper
  end
end

class GatewayMapper
protected
  def config
    @config ||= {
      gateway1_login: ENV['PAYMENT_GATEWAY_1_USER'],
      gateway1_password: ENV['PAYMENT_GATEWAY_1_PASS'],
      gateway2_login: ENV['PAYMENT_GATEWAY_2_USER'],
      gateway2_password: ENV['PAYMENT_GATEWAY_2_PASS'],
    }
  end
end

class SecurePayMapper < GatewayMapper
  def name
    "SecurePay"
  end
  
  def gateway
    SecurePayAuWithFraudGuardGateway.new :login => config[:gateway1_login], :password => config[:gateway1_password]
  end
  
  def reference(transaction)
    [transaction.bank_ref, transaction.txn_ref].join('*')
  end
  
  def build_purchase_options(donation, ip, with_trigger)
    options = {}
    options[:order_id] = donation.id
    options[:first_name] = donation.user.first_name unless donation.user.first_name.blank?
    options[:last_name] = donation.user.last_name unless donation.user.last_name.blank?
    options[:zip_code] = donation.user.postcode_number unless donation.user.postcode_number.blank?
    options[:billing_country] = donation.user.country_iso unless donation.user.country_iso.blank?
    options[:email] = donation.user.email unless donation.user.email.blank?
    options[:disable_fraudguard] = true if donation.page && donation.page.tag_list.include?('disable-fraudguard')
    options[:ip] = ip
    options[:recurring] = true if with_trigger && donation.card_supports_recurring_flag?
    options
  end
  
  def create_purchase_transaction(donation, response, ip_address)
    Transaction.create!(
      :donation => donation,
      :amount_in_cents => response.params["amount"],
      :txn_ref => response.params['purchase_order_no'] ? response.params['purchase_order_no'] : response.params['ponum'],
      :bank_ref => response.params['txn_id'],
      :message => response.message,
      :response_code => response.params['response_code'],
      :successful => response.success?,
      :action_type => response.params['action_type'],
      :settled_on => response.params['settlement_date'],
      :invoiced => true,
      :ip_address => ip_address,
      :gateway_name => response.params["gateway_name"],
      :recurring_flag => response.params["recurring_flag"] == 'yes',
    )
  end
  
  def create_refund_transaction(purchase_transaction, response)
    Transaction.create!(
      :donation_id => purchase_transaction.donation_id,
      :amount_in_cents => "-#{response.params['amount']}",
      :bank_ref => response.params["txn_id"],
      :txn_ref => response.params["purchase_order_no"] ? response.params["purchase_order_no"] : response.params["ponum"],
      :message => response.message,
      :response_code => response.params['response_code'],
      :successful => response.success?,
      :action_type => response.params['action_type'],
      :refund_of => purchase_transaction,
      :gateway_name => purchase_transaction.gateway_name
    )
  end
end

class FatZebraMapper < GatewayMapper
  def name
    "Fat Zebra"
  end
  
  def gateway
    ActiveMerchant::Billing::FatZebraGateway.new :username => config[:gateway2_login], :token => config[:gateway2_password]
  end
  
  def reference(transaction)
    transaction.bank_ref
  end
  
  def build_purchase_options(donation, ip, trigger)
    options = {}
    options[:order_id] = donation.id
    options[:ip] = ip
    options
  end
  
  def create_purchase_transaction(donation, response, ip_address)
    Transaction.create!(
      :donation => donation,
      :amount_in_cents => response.params["response"]["amount"],
      :txn_ref => response.params["response"]["reference"],
      :bank_ref => response.params["response"]["transaction_id"],
      :message => response.message,
      :response_code => response.params["response"]['response_code'],
      :successful => response.success?,
      :action_type => nil,
      :settled_on => response.params["response"]['settlement_date'],
      :invoiced => true,
      :ip_address => ip_address,
      :gateway_name => response.params["gateway_name"]
    )
  end
  
  def create_refund_transaction(purchase_transaction, response)
    Transaction.create!(
      :donation_id => purchase_transaction.donation_id,
      :amount_in_cents => "-#{response.params["response"]['amount']}",
      :bank_ref => response.params["response"]["transaction_id"],
      :txn_ref =>  response.params["response"]["reference"],
      :message => response.message,
      :response_code => response.params["response"]['response_code'],
      :successful => response.success?,
      :refund_of => purchase_transaction,
      :gateway_name => purchase_transaction.gateway_name
    )
  end
end

GatewaySwitcher.gateway1_mapper = SecurePayMapper.new
GatewaySwitcher.gateway2_mapper = FatZebraMapper.new

if Rails.env.test?
  class GatewayMapper
    def self.unique_ref
      @unique_ref ||= Time.now.to_f.to_s.sub('.','')
    end
    
    def self.reset_ref
      @unique_ref = nil
    end
  end
  
  # need a unique reference for gateway sandboxes
  [SecurePayMapper, FatZebraMapper].each do |mapper_clazz|
    mapper_clazz.class_eval do
      alias_method :original_build_purchase_options, :build_purchase_options
      def build_purchase_options(donation, ip, with_trigger)
        original_build_purchase_options(donation, ip, with_trigger).merge(:order_id => GatewayMapper.unique_ref)
      end
    end
  end
  
  class TestGatewayMapper
    def initialize(sandbox_gateway_mapper)
      @sandbox_gateway_mapper = sandbox_gateway_mapper
    end
    
    def gateway
      if ENV['USE_PROVIDER_GATEWAY'] == 'true'
        @sandbox_gateway_mapper.gateway
      else
        ActiveMerchant::Billing::BogusGateway.new
      end
    end
    
    def method_missing(method, *args)
      @sandbox_gateway_mapper.send(method, *args)
    end
  end
  
  GatewaySwitcher.gateway1_mapper = TestGatewayMapper.new(GatewaySwitcher.gateway1_mapper)
  GatewaySwitcher.gateway2_mapper = TestGatewayMapper.new(GatewaySwitcher.gateway2_mapper)
end
