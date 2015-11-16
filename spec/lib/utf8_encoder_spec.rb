require File.join(File.dirname(__FILE__), "../spec_helper")

describe Utf8Encoder do
  describe "::clean_to_utf8" do
    it "should handle empty hash" do
      log = Utf8Encoder.clean_to_utf8({})
      log.should == {}
    end

    it "should clean all keys and values" do
      log = { :method => "GET", :path => "mypath\xE2".force_encoding('ASCII-8BIT'), :params => {"\255hi" => 'something'} }
      log = Utf8Encoder.clean_to_utf8(log)
      log[:method].should == 'GET'
      log[:path].should == "mypath?"
      log[:params]['?hi'].should == 'something'
    end
  end
end
