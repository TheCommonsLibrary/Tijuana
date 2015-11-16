require File.expand_path(File.dirname(__FILE__) + "../../../spec_helper")

describe Admin::LinkShortenerController do
  describe '#generate_shortened_url' do
    before :each do
      sign_in create(:admin_user)
    end

    it 'should return correct url' do
      user_id, email_id, page_id, redirect_id = 1111,33,44,55
      hash = Hashids.new(AppConstants.link_shortener_salt).encode(user_id,email_id,page_id,redirect_id)
      get  'generate_shortened_url', {user_id: user_id, email_id: email_id, page_id: page_id, redirect_id: redirect_id}
      response.status.should == 200
      response.body.should == "http://getup.to/#{hash}"
    end
  end
end
