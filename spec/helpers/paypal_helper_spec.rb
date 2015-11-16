require File.expand_path(File.dirname(__FILE__) + "../../spec_helper")

describe PaypalHelper do
  include VanityTestHelper
  
  before :each do
    @page  = create(:page_with_parent, :required_user_details => {:first_name => :required})
    @page_sequence = @page.page_sequence
    @campaign = @page_sequence.campaign
    @donationmodule = create(:donation_module)
    ContentModuleLink.create!(:page => @page, :content_module => @donationmodule)
  end

  describe "#paypal_return_url" do
    context "cloaked domain" do
      before(:each) do
        @request.host = 'content.communityrun.org'
      end

      it "should return the cloaked domain URL" do
        helper.paypal_return_url(@campaign, @page_sequence, @page).should == "http://content.communityrun.org/#{@page_sequence.id}/#{@page.id}/paypal_completed"
      end
    end

    context "getup domain" do
      it "should return the full campaign URL" do
        helper.paypal_return_url(@campaign, @page_sequence, @page).should == "http://test.host/campaigns/#{@campaign.id}/#{@page_sequence.id}/#{@page.id}/paypal_completed"
      end
    end
  end

  describe '#paypal_form' do
    without_transactional_fixtures do
      it "should correctly point to paypal and substitute template variables" do
        with_push_table do
          user = create(:user)
          email = create(:email)
          token = EmailTrackingToken.encode(user.id, email.id)
          @page.reload
          form = helper.paypal_form(@page, token)
  
          form.should include(%Q{<input type="hidden" name="business" value="DQ96F785WLS74">})
          form.should include(%Q{name="item_name" value="Dummy Campaign Name"})
          form.should include(%Q{name="item_number" value="#{@campaign.id}"})
          form.should include(%Q{name="notify_url" value="http://httpresponder.com/tijuana-paypal-debug?#{@page.id}-#{@donationmodule.id}-#{token}--"})
          form.should include(%Q{name="cancel_return" value="#{paypal_cancel_page_url(@campaign, @page_sequence, @page)}"})
          form.should include(%Q{name="return" value="#{paypal_completed_page_url(@campaign, @page_sequence, @page)}"})
        end
      end
    end
  
    it 'should not include an invalid token as substituted template variables' do
      token = EmailTrackingToken.encode(1, -1)
      @page.reload
      form = helper.paypal_form(@page, token)
  
      form.should include(%Q{<input type="hidden" name="business" value="DQ96F785WLS74">})
      form.should include(%Q{name="item_name" value="Dummy Campaign Name"})
      form.should include(%Q{name="item_number" value="#{@campaign.id}"})
      form.should include(%Q{name="notify_url" value="http://httpresponder.com/tijuana-paypal-debug?#{@page.id}-#{@donationmodule.id}---"})
      form.should include(%Q{name="cancel_return" value="#{paypal_cancel_page_url(@campaign, @page_sequence, @page)}"})
      form.should include(%Q{name="return" value="#{paypal_completed_page_url(@campaign, @page_sequence, @page)}"})
    end

    it 'should include an acquisition source token in the notify url' do
      token = EmailTrackingToken.encode_with_source(create(:acquisition_source).id)
      @page.reload
      form = helper.paypal_form(@page, token)
      form.should be_include(token)
      form.should match("name=\"notify_url\" value=\".*#{token}.*\"")
    end
  
    it "should rename generous campaign to 'Campaign General'" do
      @campaign.name = 'generous'
      @campaign.save
      @page.reload
      form = helper.paypal_form(@page, nil)
      form.should include(%Q{name="item_name" value="Campaign General"})
    end

    it "should protect against XSS" do
      xss = "\"/><script>alert('hi')</script>"
      helper.request.cookies["vanity_id_v3"] = xss
      form = helper.paypal_form(@page, nil)
      form.should_not include(xss)
    end
  end
  
  describe '#paypal_ipn_url' do
    without_transactional_fixtures do
      it 'should include the token when valid token' do
        with_push_table do
          user = create(:user)
          email = create(:email)
          token = EmailTrackingToken.encode(user.id, email.id)
          url = helper.paypal_ipn_url(@page, token)
          url.should match /#{token}/
        end
      end

    end
    
    context "with a vanity identity set as a cookie" do
      let!(:identity) { 'someid' }
      let!(:mock_cookies) { double }
      before do
        helper.stub(cookies: mock_cookies)
      end

      it "should include the vanity_id in the url" do
        mock_cookies.should_receive(:[]).with('vanity_id_v3').and_return(identity)
        helper.paypal_ipn_url(@page, nil).should match(/#{identity}/)
      end
    end

    it 'should not include the token when invalid token' do
      token = "bogus_token"
      url = helper.paypal_ipn_url(@page, token)
      url.should_not match /#{token}/
    end

    context "URLs with experiment IDs" do
      let!(:user) { create(:user) }
      let!(:email) { create(:email) }
      let(:token) { EmailTrackingToken.encode(user.id, email.id) }
      let!(:experiment1) { new_ab_test(:experiment1) }
      let!(:experiment2) { new_ab_test(:experiment2) }

      it "should include experiment IDs" do
        session[VanityHelper::SESSION_KEY_EXPERIMENTS] = [experiment1.id]
        helper.paypal_ipn_url(@page, token).should match /-1$/
      end

      it "should work with no experiments" do
        session[VanityHelper::SESSION_KEY_EXPERIMENTS] = []
        helper.paypal_ipn_url(@page, token).should match /-$/
      end
      
      it "should work with multiple experiments" do
        session[VanityHelper::SESSION_KEY_EXPERIMENTS] = [experiment1.id, experiment2.id]
        helper.paypal_ipn_url(@page, token).should match /-1,2$/
      end
    end
  end
end
