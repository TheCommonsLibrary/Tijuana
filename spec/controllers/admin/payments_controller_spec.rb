require File.expand_path(File.dirname(__FILE__) + "../../../spec_helper")

describe Admin::PaymentsController do
  
  before :each do
    sign_in create(:admin_user)
  end

  it "should split IP addresses and save them separately" do
    ip_addresses = "1.1.1.1,2.2.2.2\n3.4.6.54 43.54.3.4"
    put :set_blocked_ips, ip_addresses: ip_addresses
    @blocked_ips = BlockedIp.all
    @blocked_ips.size.should == 4
    ips = @blocked_ips.collect {|ip| ip.ip_address }
    ['1.1.1.1', '2.2.2.2', '3.4.6.54', '43.54.3.4'].each do |ip_addr|
      ips.include?(ip_addr).should be true
    end
  end

  it "should display error when IP addresses are invalid" do
    ip_addresses = "333.1.1.1,2.2.2.2,2.2.2.2"
    put :set_blocked_ips, ip_addresses: ip_addresses
    flash[:error].should include('Changes not saved.')
    response.should be_success
  end

  it "should ignore blank entries" do
    ip_addresses = "  ,  1.1.1.1,22.2.22.2"
    put :set_blocked_ips, ip_addresses: ip_addresses
    flash[:error].should be_nil
    response.should be_redirect
  end

  describe "#set_fraud_guard" do
    it "should enable fraud guard" do
      Setting[:use_fraud_guard].should be_nil
      put :set_fraud_guard, fraud_guard: 'enabled'
      Setting[:use_fraud_guard].should == 'true'
    end

    it "should disable fraud guard" do
      Setting[:use_fraud_guard] = 'true'
      put :set_fraud_guard, fraud_guard: 'disabled'
      Setting[:use_fraud_guard].should be_nil
    end
  end
  
  describe "#set_gateway1_percentage" do
    it "should not allow non numbers" do
      put :set_gateway1_percentage, gateway1_percentage: "richy likes food"
      flash[:error].should include("percentage is not a valid number")
      response.should be_success
    end
    
    it "should not allow numbers outside of range (0 to 100)" do
      put :set_gateway1_percentage, gateway1_percentage: "101"
      flash[:error].should include("percentage is not a valid number")
      response.should be_success
    end
    
    it "should allow numbers within range" do
      put :set_gateway1_percentage, gateway1_percentage: "100"
      flash[:error].should be_nil
      response.should be_redirect
    end
  end
end
