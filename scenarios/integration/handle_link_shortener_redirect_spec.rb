require File.dirname(__FILE__) + "/../scenario_helper.rb"
describe 'HandleLinkShortenerRedirect', type: :request do
  context 'receives a shortened url' do
    it 'should redirect to page url with no token when only page_id present' do
      campaign = create(:campaign)
      page_sequence = create(:page_sequence, campaign: campaign)
      page = create(:page, page_sequence: page_sequence)
      host! 'getup.to'
      hashids = Hashids.new(AppConstants.link_shortener_salt)
      hash = hashids.encode(0,0,page.id,0)
      get "/#{hash}"
      response.status.should  == 302
      response.location.should == "http://localhost/campaigns/#{campaign.id}/#{page_sequence.id}/#{page.id}"
    end

    it 'should redirect to page url with token when user_id, email_id and page_id present' do
      with_push_table do
        user = create(:user)
        email = create(:email)
        campaign = create(:campaign)
        page_sequence = create(:page_sequence, campaign: campaign)
        page = create(:page, page_sequence: page_sequence)
        token = EmailTrackingToken.encode(user.id,email.id)
        host! 'getup.to'
        hashids = Hashids.new(AppConstants.link_shortener_salt)
        hash = hashids.encode(user.id,email.id,page.id,0)
        get "/#{hash}"
        response.status.should  == 302
        response.location.should == "http://localhost/campaigns/#{campaign.id}/#{page_sequence.id}/#{page.id}?t=#{token}"
      end
    end

    it 'should redirect to redirect target with token when user_id, email_id, redirect_id present' do
      with_push_table do
        user = create(:user)
        email = create(:email)
        token = EmailTrackingToken.encode(user.id,email.id)
        redirect = create(:redirect_path, alias_path: 'test', target: 'http://example.com')
        host! 'getup.to'
        hashids = Hashids.new(AppConstants.link_shortener_salt)
        hash = hashids.encode(user.id,email.id,0,redirect.id)
        get "/#{hash}"
        response.status.should  == 302
        response.location.should == "http://example.com?t=#{token}"
      end
    end
  end
end
