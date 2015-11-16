require 'spec_helper'

describe DonationService, :vcr_off => true do
  let(:vary_by_amount_card_number) { '4111 1111 1111 1111' }
  let(:sucessful_amount) { 2000 }
  let(:insufficient_credit_amount) { 2051 }
  
  before :all do
    ENV['USE_PROVIDER_GATEWAY'] = 'true'
  end
  
  after(:all) do
    ENV['USE_PROVIDER_GATEWAY'] = ''
  end
  
  before :each do
    @service = DonationService.new
    @donation = create :donation, :card_number => vary_by_amount_card_number, name_on_card: 'tom mann', card_expiry_year: '2018', card_expiry_month: '09', amount_in_cents: 2000
  end
  
  it 'expects ActiveMerchant::Billing::SecurePayAuGateway to have certain methods to override in SecurePayAuWithFraudGuardGateway' do
    gateway = ActiveMerchant::Billing::SecurePayAuGateway.new :login => nil, :password => nil
    gateway.respond_to? :test_url
    gateway.respond_to? :live_url
    gateway.respond_to? :build_purchase_request
  end
  
  context "with fraudguard on"  do
    before { Setting[:use_fraud_guard] = 'true' }
    after { Setting[:use_fraud_guard] = 'false' }

    it "should return fraud filter message" do
      @donation.amount_in_cents = 200000000
      @service.process! @donation, ip: '203.1.34.253'
      @donation.errors[:credit_card].first.should match(/payment failed/i)
    end

    context "with fraudguard disabled for the page"  do
      let!(:page_with_fraudguard_disabled ) { create(:page_with_parent, tag_list: 'disable-fraudguard') }
      before do
        @donation.page = page_with_fraudguard_disabled
        @donation.save!
      end

      it "should not return suspected fraud" do
        @donation.amount_in_cents = 200000000
        @service.process! @donation, ip: '203.1.34.253'
        @donation.errors[:credit_card].should be_empty
      end
    end
  end
  
  context "with fraudguard off" do
    before { Setting[:use_fraud_guard] = nil }

    it "should not return suspected fraud" do
      @donation.amount_in_cents = 200000000
      @service.process! @donation, ip: '203.1.34.253'
      @donation.errors[:credit_card].should be_empty
    end
  end
  
  ['securepay', 'securepay_fraudguard'].each do |config|
    
    describe "#{config} should perform all important payment operations" do
      before :each do
        case config
        when 'securepay'
          Setting[:gateway1_percentage] = 100
          Setting[:use_fraud_guard] = nil
        when 'securepay_fraudguard'
          Setting[:gateway1_percentage] = 100
          Setting[:use_fraud_guard] = 'true'
        when 'fatzebra'
          Setting[:gateway1_percentage] = 0
        end
      end
    
      it "should perform successful purchase" do
        @service.process! @donation, ip: '203.1.34.253'
        transaction = @donation.transactions.first
        transaction.message.should == "Approved"
        transaction.amount_in_cents.should == sucessful_amount
        transaction.donation.should == @donation
        transaction.txn_ref.should == GatewayMapper.unique_ref
        transaction.bank_ref.should be # generated by gateway
        transaction.response_code.should == "00"
        transaction.successful.should == true
        transaction.action_type.should be_nil
        transaction.settled_on.should >= Date.today
        transaction.invoiced.should == true
        transaction.ip_address.should == "203.1.34.253"
      end
      
      it "should record failure correctly for insufficient credit" do
        @donation.amount_in_cents = insufficient_credit_amount
        @service.process! @donation, ip: '203.1.34.253'
        @donation.transactions.first.message.should == "Insufficient Funds"
        @donation.transactions.first.amount_in_cents.should == insufficient_credit_amount
      end
    
      it "should perform successful purchase from stored trigger" do
        # need to add trigger id tests to mappers when we play that card
        pending "fatzebra purchase from trigger out of scope for now" if config == "fatzebra"
        @service.setup_recurring_donation_with_trigger @donation, ip: '203.1.34.253'
        @service.trigger_recurring_payment! @donation, ip: '203.1.34.253'
        @donation.transactions.successful.select { |t| t.amount_in_cents = sucessful_amount }.count.should == 2
        transaction = @donation.transactions.last
        transaction.action_type.should == "trigger"
        expect(transaction.recurring_flag).to be true
      end

      context "if the card is AMEX" do
        before do
          @donation.card_number = '378282246310005'
          @donation.save!
          @service.setup_recurring_donation_with_trigger @donation, ip: '203.1.34.253'
          @service.trigger_recurring_payment! @donation, ip: '203.1.34.253'
        end
        it "should perform successful purchase from stored trigger" do
          @donation.transactions.successful.select { |t| t.amount_in_cents = sucessful_amount }.count.should == 2
          transaction = @donation.transactions.last
          transaction.action_type.should == "trigger"
          expect(transaction.recurring_flag).to be false
        end
      end

      [[2000, 2000], [2000, 100]].each do |purchase_amount, refund_amount|
        it "should purchase #{purchase_amount}, then refund #{refund_amount}" do
          @donation.amount_in_cents = purchase_amount
          @service.process! @donation, ip: '203.1.34.253'
          @service.refund refund_amount, @donation.transactions.first
          payment_transaction, refund_transaction = @donation.transactions
          payment_transaction.amount_in_cents.should == purchase_amount
          refund_transaction.amount_in_cents.should == -refund_amount
        end
      end
    end
  end
end