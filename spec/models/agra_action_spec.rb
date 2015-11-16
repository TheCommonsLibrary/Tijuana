require File.expand_path(File.dirname(__FILE__) + "../../spec_helper")

describe AgraAction do
  it 'should return Unknown campaign name if no slug (for some strange reason)' do
    AgraAction.new(:slug => nil).campaign_name.should == 'Unknown'
    AgraAction.new(:slug => '').campaign_name.should == 'Unknown'
  end
end