require 'spec_helper'

describe Setting do
  it "should handle long text in the value" do
    expect(Setting.create(key: 'test', value: 'test'*100)).to_not be_nil
  end

  it "should set and retrieve settings" do
    Setting['mykey'].should be_nil
    Setting['mykey'] = 'asdf'
    Setting['mykey'].should == 'asdf'
    Setting['anotherkey'].should be_nil
    Setting['anotherkey'] = 'newvalue'
    Setting['anotherkey'].should == 'newvalue'
    Setting['anotherkey'] = 'differentvalue'
    Setting['anotherkey'].should == 'differentvalue'
  end
end
