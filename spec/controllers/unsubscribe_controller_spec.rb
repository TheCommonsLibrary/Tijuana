require 'spec_helper'

describe UnsubscribeController do

  describe "GET 'new'" do
    it "should display the unsubscribe form" do
      get 'new', :t => EmailTrackingToken.encode(123, 456)
      
      assigns(:user).should_not be_nil
      response.should render_template("unsubscribe/new")
    end

    context "with a token that matches a user" do
      let(:token_user){ create(:user, email: 'test2@email.com') }
      let(:email){ create(:email) }
      let(:token){ EmailTrackingToken.encode(token_user.id, email.id) }

      it "should set @token_user" do
        get 'new', :t => EmailTrackingToken.encode(token_user.id, email.id)
        assigns(:token_user).should_not be_nil
        assigns(:token_user).id.should == token_user.id
      end
    end
  end

  describe "POST 'create'" do
    it "should lookup and unsubscribe the user" do
      existing_user = create(:user, email: "angry@dude.com")

      post 'create', user: { email: existing_user.email}, commit: 'Unsubscribe'
      response.should render_template("unsubscribe/create")
      assigns(:msg).should include 'cancelled'
      User.find(existing_user.id).is_member?.should == false

      post 'create', user: { email: "angry@dude.com" }, community_run: 'true', commit: 'Unsubscribe'
      response.should render_template("unsubscribe/create")
      assigns(:msg).should include 'cancelled'
      User.find(existing_user.id).is_agra_member?.should == false
    end

    it "should unsubscribe user and record email from token" do
      existing_user = create(:user, email: "angry@dude.com")
      email = create(:email)
      hash = EmailTrackingToken.encode(existing_user.id, email.id)
      
      post 'create', user: { email: "angry@dude.com" }, t: hash, commit: 'Unsubscribe'
      response.should render_template("unsubscribe/create")
      user = User.find(existing_user.id)
      user.is_member?.should == false
      unsubscribe = Unsubscribe.where(user_id: user.id, email_id: email.id).count.should == 1
      UserActivityEvent.where(user_id: user.id, activity: 'unsubscribed', email_id: email.id).count.should == 1
      event = UserActivityEvent.where(user_id: user.id, activity: 'unsubscribed', email_id: email.id).first

      post 'create', user: { email: "angry@dude.com" }, t: hash, community_run: 'true', commit: 'Unsubscribe'
      response.should render_template("unsubscribe/create")
      user = User.find(existing_user.id)
      user.is_member?.should == false
      unsubscribe = Unsubscribe.where(user_id: user.id, email_id: email.id, community_run: true).count.should == 1
    end

    context "with a request_id passed by rack and a user that is currently a member" do
      let(:user)  { create(:user, email: "angry@dude.com") }
      let(:email) { create(:email) }
      let(:event) { UserActivityEvent.where(user_id: user.id, activity: 'unsubscribed', email_id: email.id).first }
      let(:hash)  { 'somehexhashtolog' }
      
      before do
        disable_request_recycle(@request)
        @request.env['action_dispatch.request_id'] = hash
        hash = EmailTrackingToken.encode(user.id, email.id)
        post 'create', user: { email: user.email }, t: hash, commit: 'Unsubscribe'
      end

      it "should record the data about the unsubscribe user activity event in @events_to_log" do
        events = assigns(:events_to_log)
        events.length.should == 1
        events.first.should == {
          "id" => event.id,
          "source" => event.source,
          "activity" => event.activity.to_s,
          "content_module_type" => event.content_module_type,
          "acquisition_source_id" => nil
        }
      end

    end

    it "should record the unsubscribe reason" do
      existing_user = create(:user, email: "angry@dude.com")

      post 'create', user: { email: 'angry@dude.com'}, reason: 'campaign or tactic', reason_campaign_or_tactic_field: 'waste of money' , commit: 'Unsubscribe'
      unsubscribe = Unsubscribe.where(user_id: existing_user.id)
      unsubscribe.count.should == 1
      unsubscribe.first.reason.should == 'campaign or tactic'
      unsubscribe.first.specifics.should == 'waste of money'

      post 'create', user: { email: 'angry@dude.com'}, reason: 'campaign or tactic', reason_campaign_or_tactic_field: 'dolphins are not my thing',
            community_run: 'true', commit: 'Unsubscribe'
      unsubscribe = Unsubscribe.where(user_id: existing_user.id, community_run: true)
      unsubscribe.count.should == 1
      unsubscribe.first.reason.should == 'campaign or tactic'
      unsubscribe.first.specifics.should == 'dolphins are not my thing'
    end

    context "when 'specific campaigns' is chosen" do
      let!(:existing_user) { create(:user, email: "angry@dude.com") }

      it "records specific campaigns that they'd opt out of" do
        post "create",
          user: {email: "angry@dude.com"},
          commit: "Unsubscribe",
          reason: "specific campaigns",
          specific_campaigns: { "asylum_seekers" => "1", "medicare" => "1" }

        unsubscribe = Unsubscribe.where(user_id: existing_user.id)
        unsubscribe.first.reason.should == "specific campaigns"
        unsubscribe.first.specifics.should == "asylum_seekers,medicare"
      end

      it "doesn't blow up when they deselect everything" do
        expect {
          post "create",
            user: {email: "angry@dude.com"},
            commit: "Unsubscribe",
            reason: "specific campaigns"
        }.not_to raise_error
      end
    end

    it 'should unsubscribe a user only once' do
      existing_user = create(:user, email: "angry@dude.com")
      disable_request_recycle(@request)
      @request.env['action_dispatch.request_id'] = 'uniquehash'
      post 'create', user: { email: 'angry@dude.com'}, reason: 'campaign or tactic', reason_campaign_or_tactic_field: 'waste of money' , commit: 'Unsubscribe'
      @request.env['action_dispatch.request_id'] = 'anotherhash'
      post 'create', user: { email: 'angry@dude.com'}, reason: 'other', reason_other_field: 'something else' , commit: 'Unsubscribe'

      Unsubscribe.where(user_id: existing_user.id).count.should == 1
      UserActivityEvent.where(user_id: existing_user.id, activity: 'unsubscribed').count.should == 1
      event = UserActivityEvent.where(user_id: existing_user.id, activity: 'unsubscribed').first
      assigns(:events_to_log).first["id"].should == event.id
    end

    describe "Unsubscribe from GetUp" do
      context "low volume enabled" do
        before(:each) do
          AppConstants.stub(:low_volume_enabled).and_return(true)
        end

        it "should lookup the user and email and set to low volume" do
          existing_user = create(:user, email: "busy@dude.com")
          User.stub(:find_by_email).and_return(existing_user)
          email = create(:email)
          token = EmailTrackingToken.encode(existing_user.id, email.id)
          Email.stub(:find).and_return(email)
          user_activity_event = UserActivityEvent.new
          user_activity_event.should_receive(:attributes).and_return({'id' => user_activity_event.id, 'source' => 'test', 'activity' => ':unsubscribed' })
          existing_user.should_receive(:set_low_volume!).with(email).and_return(user_activity_event)

          disable_request_recycle(@request)
          @request.env['action_dispatch.request_id'] = 'uniquehash'
          post 'create', user: { email: "busy@dude.com" }, t: token, commit: 'Send me less email'
          assigns(:user).should == existing_user
          response.should render_template("unsubscribe/create")
          assigns(:msg).should include 'most important'
          assigns(:events_to_log).first["id"].should == user_activity_event.id
        end
      end

      context "low volume disabled" do
        before(:each) do
          AppConstants.stub(:low_volume_enabled).and_return(false)
        end

        it "should lookup the user and unsubscribe them" do
          existing_user = create(:user, email: "busy@dude.com")
          User.stub(:find_by_email).and_return(existing_user)
          hash = EmailTrackingToken.encode(123, 456)
          email = create(:email)
          Email.stub(:find).and_return(email)
          existing_user.should_not_receive(:set_low_volume!).with(email)

          post 'create', user: { email: "busy@dude.com" }, t: hash, commit: 'Send me less email'
          assigns(:user).should == existing_user
          response.should render_template("unsubscribe/create")
          assigns(:msg).should include 'cancelled'
        end
      end
    end

    it "should accept emails with leading and trailing space" do
      email = "auser@emailaddress.com"
      existing_user = create(:user, email: email)

      post 'create', user: { email: '   auser@emailaddress.com   ' }
      assigns(:user).email.should == email
    end

    it "should redirect to the unsubscribe page if an invalid email is provided" do
      post_and_assert_error("I@dontExist.com", "The email provided doesn't seem to belong to any user.")
      post_and_assert_error("", "Please enter your email address.")
      post_and_assert_error("invalid", "This is not a valid email address.")
    end

    it "should redirect to unsubscribe form if no user parameter is supplied" do
      post :create
      response.should redirect_to unsubscribe_path
    end
  end

  def post_and_assert_error(email_address, msg)
    post 'create', :user => {:email => email_address}
    assigns(:user).email.should == email_address
    response.should render_template("unsubscribe/new")
    flash[:alert].should == msg 
  end

  # This is needed or else the recycle! method on request will wipe out
  # .env['action_dispatch.request_id]
  def disable_request_recycle(request)
    request.instance_eval do
      def recycle!; end
    end
  end
end
