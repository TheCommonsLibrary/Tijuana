require File.dirname(__FILE__) + "/../scenario_helper.rb"
describe 'CloakedDomainRoute', type: :request do
  describe "root" do
    it 'should display homepage when not a cloaked domain' do
      create(:homepage, :banner_text => 'getup_homepage')
      MemberCountCalculator.init
      get '/'
      response.body.should include 'getup_homepage'
    end

    it 'should display the page sequence page when a cloaked domain and has a homepage_sequence' do
      campaign = create(:campaign, :name => 'test_campaign')
      page_sequence = create(:page_sequence, :name => 'test_ps', :campaign => campaign)
      create(:page, :name => 'test_page', :page_sequence => page_sequence)
      setup_cloaked_domains_stub('test.example.com', {'campaign' => 'test_campaign', 'homepage_sequence' => 'test_ps'})
      host! 'test.example.com'
      get '/'
      response.body.should include 'test_page'
    end

    it 'should redirect to cloaked domain url when a cloaked domain and has a homepage_url' do
      setup_cloaked_domains_stub('test.example.com', {'homepage_url' => 'http://www.google.com'})
      host! 'test.example.com'
      get '/'
      response.status.should == 301
      response.location.should == 'http://www.google.com'
    end
  end
end

def setup_cloaked_domains_stub(domain, details)
  cd = double()
  cd.stub(:constants_hash).and_return(domain => details)
  AppConstants.stub(:cloaked_domains).and_return(cd)
end