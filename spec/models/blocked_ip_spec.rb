require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe BlockedIp do
  specify { BlockedIp.new(ip_address: 'asdf').valid?.should be false }
  specify { BlockedIp.new(ip_address: 'a.a.a.a').valid?.should be false }
  specify { BlockedIp.new(ip_address: '239.324.43.34').valid?.should be false }
  specify { BlockedIp.new(ip_address: '1.2.3.4.5').valid?.should be false }
  specify { BlockedIp.new(ip_address: '1.2.3.4').valid?.should be true }
  specify { 
    BlockedIp.new(ip_address: '1.2.3.4').save!
    BlockedIp.new(ip_address: '1.2.3.4').valid?.should be false
  }
end
