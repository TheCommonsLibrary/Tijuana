require File.expand_path(File.dirname(__FILE__) + "../../spec_helper")

describe BeaconController do

  shared_examples "returns a gif" do |endpoint|
    it "returns a mime-type of text/gif for all requests" do
      response = get endpoint, t: 'random'
      response.headers["Content-Type"].should == "image/gif"
    end

    it "returns a status code of 200 with non-base64 encoded data passed" do
      response = get endpoint, :t => "borked"
      response.status.should == 200
    end
  end

  describe "index" do

    it_behaves_like 'returns a gif', :index

    it "returns a status code of 200 with no data passed" do
      response = get :index
      response.status.should == 200  
    end

    it "records an email viewed! user activity event against the specified user" do
      @user = create(:user)
      @email = create(:email)
      UserActivityEvent.should_receive(:email_viewed!).with(@user, @email)
      get :index, :t => EmailTrackingToken.encode(@user.id, @email.id)
      assigns(:token_user).id.should == @user.id
    end   

  end

  describe "track_email_target" do

    before{ UserEmail.stub(find_by_token: nil) }

    it_behaves_like 'returns a gif', :track_email_target

    context "with a t parameter that matches an existing UserEmail record" do
      let(:user_email_record){ mock(UserEmail, id: 3) }
      let(:existing_user_email){ create(:user_email) }
      let(:long_user_agent){ 'Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 6.2; WOW64; Trident/7.0; .NET4.0E; .NET4.0C; .NET CLR 3.5.30729; .NET CLR 2.0.50727; .NET CLR 3.0.30729; Tablet PC 2.0; McAfee; MALCJS; Microsoft Outlook 15.0.4701; Microsoft Outlook 15.0.4701; ms-office; MSOffice 15)' }
      let(:long_referrer){ 'referrer!' * 1000 }

      it "creates a UserEmailTrackingLog record" do
        @request.env['HTTP_REFERER'] = long_referrer
        @request.user_agent = long_user_agent
        get :track_email_target, t: EmailTargetTrackingLog.generate_token(existing_user_email)
        record = EmailTargetTrackingLog.last
        record.user_email.should == existing_user_email
        record.referrer.should == long_referrer
        record.agent.should == long_user_agent
        record.ip.should == '0.0.0.0'
      end
    end
  end

  describe "track_event" do

    it_behaves_like 'returns a gif', :track_event

    context "with invalid json data" do
      let(:invalid_json_payload){ Base64.encode64('blah blah. invalid') }
      specify{ expect(get(:track_event, t: invalid_json_payload).status).to eq(200) }
    end

    context "with a base64 encoded json payload" do

      let(:data){ {name: 'subscribe', context: 'test'} }
      let(:payload){ Base64.encode64(data.to_json) }

      context "with no matching user data" do
        specify{ expect(get(:track_event, t: payload).status).to eq(200) }

        it "should not create a new EventTrackingLog" do
          expect(EventTrackingLog).to_not receive(:create!)
        end
      end

      context "with a matching user" do
        let!(:referrer){ 'https://getup.org.au' }
        let!(:agent){ 'Rails test' }
        let!(:user){ create(:user) }

        before do
          @request.env['HTTP_REFERER'] = referrer
          @request.user_agent = agent
          request.cookies['user_track'] = user.id.to_s
        end

        specify{ expect(get(:track_event, t: payload).status).to eq(200) }

        it "should make an event tracking record that stores user_id, time, device and event, referrer and agent string" do
          get :track_event, t: payload
          logs = EventTrackingLog.where(user_id: user.id)
          expect(logs.count).to eq(1)
          log = logs.first
          expect(log.name).to eq(data[:name])
          expect(log.context).to eq(data[:context])
          expect(log.agent).to eq(agent)
          expect(log.referrer).to eq(referrer)
          expect(log.ip).to be_present
        end
      end
    end
  end
end
