require File.expand_path(File.dirname(__FILE__) + "../../spec_helper")

describe PaypalController do

  describe "ipn" do

    it "should delegate to PaypalPaymentNotificationHandler and pass parameters and raw post data" do
      handler = double(PaypalPaymentNotificationHandler)

      params = {id: 'page-module'}
      raw_post_data = 'SomeSpecificPostData=SomeValue'
      PaypalPaymentNotificationHandler.should_receive(:new).with(hash_including(params), raw_post_data).and_return(handler)
      handler.should_receive(:verify_and_handle_ipn)

      raw_post :ipn, params, raw_post_data

    end

  end

  describe '#user_id_from_params' do
    it "should find the user and return the id" do
      user = create(:user, email: 'user@example.com')
      params = {
        'payer_email' => 'user@example.com'
      }
      result = subject.send(:user_id_from_params, params)
      result.should == user.id
    end

    it "should return empty string" do
      result = subject.send(:user_id_from_params, {})
      result.should == ''
    end
  end

  describe '#token_from_params' do
    it "should return the token" do
      params = {
        'id' => '1-2-token'
      }
      result = subject.send(:token_from_params, params)
      result.should == 'token'
    end

    it "should return empty string" do
      result = subject.send(:token_from_params, {})
      result.should == ''
    end
  end

  describe '#token_user_id_from_params' do
    without_transactional_fixtures do
      it "should find the user and return the token_user_id" do
        with_push_table do
          user = create(:user, email: 'user@example.com')
          email = create(:email)
          token = EmailTrackingToken.encode(user.id, email.id)
          params = {
            'id' => "1-2-#{token}"
          }
          result = subject.send(:token_user_id_from_params, params)
          result.should == user.id
        end
      end
    end

    it "should return empty string" do
      result = subject.send(:token_user_id_from_params, {})
      result.should == ''
    end
  end

  def raw_post(action, params, body)
    begin
      @request.env['RAW_POST_DATA'] = body
      post(action, params)
    ensure
      @request.env.delete('RAW_POST_DATA')
    end
  end


end
