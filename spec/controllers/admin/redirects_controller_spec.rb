require File.expand_path(File.dirname(__FILE__) + "../../../spec_helper")

describe Admin::RedirectsController, :vcr_off => true do

  before :each do
    sign_in create(:admin_user)
  end

  describe "#create" do
    it "should create redirect for path" do
      post :create, redirect: {alias_path: 'live', target: 'http://getup.org.au'}
      Redirect.first.alias_path.should == 'live'
      Redirect.first.alias_domain.should be_nil
    end

    it "should create redirect for domain" do
      post :create, redirect: {alias_domain: 'ozvote.org', target: 'http://getup.org.au'}
      Redirect.first.alias_path.should be_nil
      Redirect.first.alias_domain.should == 'ozvote.org'
    end

    it 'should call LinksLiveValidator to validate target url' do
      target = 'getup.org.au/election/live/'
      LinksLiveValidator.should_receive(:is_url_reachable?).with(target)

      post :create, redirect: { alias_domain: 'ozvote.org', target: target }
    end

    describe "with invalid params" do
      it "should redirect back to create page with error message" do
        post :create, redirect: {alias_path: 'live', alias_domain: 'ozvote.org', target: 'getup.org.au/election/live/'}
        response.should render_template('new')
        flash[:error].should_not be_blank
      end

      context 'invalid external url' do
        it 'should redirect back to create page with error message' do
          post :create, redirect: { alias_path: 'test', target: 'http://invalid' }
          response.should render_template('new')
          flash[:error].should_not be_blank
        end
      end

      context 'invalid internal url' do
        it 'should redirect back to create page with error message' do
          post :create, redirect: { alias_path: 'test', target: '/invalid' }
          response.should render_template('new')
          flash[:error].should_not be_blank
        end
      end
    end
  end
end
