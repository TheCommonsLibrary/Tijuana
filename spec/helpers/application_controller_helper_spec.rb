require File.expand_path(File.dirname(__FILE__) + "../../spec_helper")

describe ApplicationControllerHelper do
  describe "#set_payload_safe" do
    let(:hash) { {keys: {} } }

    it "should set the value" do
      helper.set_payload_safe(hash[:keys], :my_key, '12345')
      hash[:keys][:my_key].should == '12345'
    end

    it "should truncate the value" do
      helper.set_payload_safe(hash[:keys], :my_key, '1234567890', 6)
      hash[:keys][:my_key].should == '123456'
    end

    it "should not add a key if value is nil" do
      helper.set_payload_safe(hash[:keys], :another_key, nil)
      hash[:keys][:another_key].should be_nil
    end
  end
end
