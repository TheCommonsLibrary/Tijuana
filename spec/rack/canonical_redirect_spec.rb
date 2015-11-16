require File.expand_path(File.dirname(__FILE__) + "../../spec_helper")

describe CanonicalRedirect do
  include Rack::Test::Methods

  def app
    Rack::Builder.app do
      use CanonicalRedirect
      run lambda { |env| [200, {'Content-Type' => 'text/plain'}, ['OK']] }
    end
  end

  before(:each) do
    @default_test_host = Rack::Test::DEFAULT_HOST
    AppConstants.stub(:host).and_return("www.getup.org.au")
  end

  after(:each) do
    Kernel::silence_warnings { Rack::Test.const_set(:DEFAULT_HOST, @default_test_host) }
  end

  def set_host_and_get(host, path, use_https=false)
    Kernel::silence_warnings { Rack::Test.const_set(:DEFAULT_HOST, host) }
    https = use_https ? {'HTTPS'=>'on', 'rack.url_scheme'=>'https', 'SERVER_PORT'=>'443'} : {}
    get path, {}, {'SERVER_NAME'=> host}.merge(https)
  end


  context "host with no redirect domains" do
    it "should not redirect" do
      set_host_and_get 'getup.org.au', '/something/or/other'
      last_response.status.should eql 200
    end
  end

  context "host with redirect domains" do

    before(:each) do
      AppConstants.stub(:redirect_domains).and_return(["getup.org.au", "getup.org", "www.getup.org"])
    end

    it "should redirect to www canonical version of domain" do
      set_host_and_get 'getup.org.au', '/something/or/other'
      last_response.status.should eql 301
      last_response.headers["Location"].should eql "http://www.getup.org.au/something/or/other"
    end

    it "should redirect to https www canonical version of domain" do
      set_host_and_get 'getup.org.au', '/something/or/other/', true
      last_response.status.should eql 301
      last_response.headers["Location"].should eql "https://www.getup.org.au/something/or/other/"
    end

    it "should redirect to canonical version of domain extension" do
      set_host_and_get 'getup.org', '/something/or/other'
      last_response.status.should eql 301
      last_response.headers["Location"].should eql "http://www.getup.org.au/something/or/other"
    end

    it "should proceed as normal for the canonical domain" do
      set_host_and_get 'www.getup.org.au', '/'
      last_response.status.should eql 200
    end

    it "should proceed as normal for https canonical domain" do
      set_host_and_get 'www.getup.org.au', '/', true
      last_response.status.should eql 200
    end

    it "should proceed as normal for any other domain" do
      set_host_and_get 'secondary.getup.org.au', '/'
      last_response.status.should eql 200
    end

    it "should proceed as normal for https any other domain" do
      set_host_and_get 'secondary.getup.org.au', '/', true
      last_response.status.should eql 200
    end

  end
end
