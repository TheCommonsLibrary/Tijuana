require File.expand_path(File.dirname(__FILE__) + "../../spec_helper")

describe CloakedDomain do
  describe '#self.find' do
    it 'should return nil if the cloaked domain is not found within AppConstants' do
      setup_cloaked_domains_stub('test.example.com', {'homepage_url'=>'http://anothersite.com'})
      CloakedDomain.find('notthissite.com').should be_nil
    end

    it 'should return an instance of cloaked domain when domain is found within AppConstants' do
      setup_cloaked_domains_stub('test.example.com', {'homepage_url'=>'http://anothersite.com'})
      CloakedDomain.find('test.example.com').should be_a CloakedDomain
    end
  end

  describe '#initialize' do
    it 'should raise an exception if both url and sequence are defined' do
      setup_cloaked_domains_stub('test.example.com', {'homepage_url'=>'http://anothersite.com','homepage_sequence'=>'a_page_sequence'})
      expect {CloakedDomain.find('test.example.com')}.to raise_error('incorrectly configured cloaked domain in AppConstants')
    end

    it 'should raise an exception if both url and sequence are not defined' do
      setup_cloaked_domains_stub('test.example.com', {})
      expect {CloakedDomain.find('test.example.com')}.to raise_error('incorrectly configured cloaked domain in AppConstants')
    end

    it 'should not raise an exception if url is defined and sequence is not defined' do
      setup_cloaked_domains_stub('test.example.com', {'homepage_url'=>'http://anothersite.com'})
      expect {CloakedDomain.find('test.example.com')}.not_to raise_error
    end

    it 'should not raise an exception if url is not defined and sequence is defined' do
      setup_cloaked_domains_stub('test.example.com', {'homepage_sequence'=>'a_page_sequence'})
      expect {CloakedDomain.find('test.example.com')}.not_to raise_error
    end
  end

  describe '#sequence' do
    it 'should return the defined sequence' do
      setup_cloaked_domains_stub('test.example.com', {'homepage_sequence'=>'a_page_sequence'})
      CloakedDomain.find('test.example.com').sequence.should == 'a_page_sequence'
    end
  end

  describe '#url' do
    it 'should return the defined url' do
      setup_cloaked_domains_stub('test.example.com', {'homepage_url'=>'http://anothersite.com'})
      CloakedDomain.find('test.example.com').url.should == 'http://anothersite.com'
    end
  end
end

describe CloakedDomainConstraint do
  describe '#self.matches?' do
    it 'should return false if the domain is not a Cloaked Domain' do
      setup_cloaked_domains_stub('test.example.com', { 'homepage_url'=>'http://anothersite.com'})
      request = setup_request_stub('notthissite.com')
      CloakedDomainConstraint.matches?(request).should be_falsey
    end

    it 'should return true if the domain is a Cloaked Domain' do
      setup_cloaked_domains_stub('test.example.com', { 'homepage_url'=>'http://anothersite.com'})
      request = setup_request_stub('test.example.com')
      CloakedDomainConstraint.matches?(request).should be_truthy
    end
  end
end

def setup_cloaked_domains_stub(domain, details)
  cd = double()
  cd.stub(:constants_hash).and_return(domain => details)
  AppConstants.stub(:cloaked_domains).and_return(cd)
end

def setup_request_stub(server_name)
  request = double()
  request.stub(:env).and_return({'SERVER_NAME'=>server_name})
  request
end
