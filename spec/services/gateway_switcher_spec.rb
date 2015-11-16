require 'spec_helper'

describe GatewaySwitcher do
  let(:donation) { create :donation }
  let(:switcher) { GatewaySwitcher }
  
  before :each do
    GatewaySwitcher.gateway1_mapper.stub(:gateway).and_return ActiveMerchant::Billing::BogusGateway.new
    GatewaySwitcher.gateway2_mapper.stub(:gateway).and_return ActiveMerchant::Billing::BogusGateway.new
  end
  
  describe "switching based on percentage" do
    it 'should process a donation with the primary gateway when primary percentage is 100' do
      Setting['gateway1_percentage'] = 100
      GatewaySwitcher.gateway1_mapper.gateway.should_receive(:purchase).and_call_original
      switcher.purchase_with_credit_card donation, {}
    end
  
    it 'should process a donation with the secondary gateway when primary percentage is 0' do
      Setting['gateway1_percentage'] = 0
      GatewaySwitcher.gateway2_mapper.gateway.should_receive(:purchase).and_call_original
      switcher.purchase_with_credit_card donation, {}
    end
  
    it "should send all traffic (including rand edge cases) to gateway1 when it is 100%" do
      Setting['gateway1_percentage'] = 100
      [1, 100].each do |random|
        switcher.stub(:random_percentage).and_return random
        GatewaySwitcher.gateway1_mapper.gateway.should_receive(:purchase).and_call_original
        switcher.purchase_with_credit_card donation, {}
      end
    end
  
    it "should send all traffic (including rand edge cases) to gateway2 when gateway1_percentage is 0%" do
      Setting['gateway1_percentage'] = 0
      [1, 100].each do |random|
        switcher.stub(:random_percentage).and_return random
        GatewaySwitcher.gateway2_mapper.gateway.should_receive(:purchase).and_call_original
        switcher.purchase_with_credit_card donation, {}
      end
    end
  
    it "should send 1% of traffic to gateway2 when gateway1 is 99%" do
      Setting['gateway1_percentage'] = 99
      switcher.stub(:random_percentage).and_return 100
      GatewaySwitcher.gateway2_mapper.gateway.should_receive(:purchase).and_call_original
      switcher.purchase_with_credit_card donation, {}
    end
  end
end