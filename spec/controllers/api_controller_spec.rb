require File.expand_path(File.dirname(__FILE__) + "../../spec_helper")

describe ApiController do

  describe "#csg_petition_signature_count" do
    it "should handle no signatures/module" do
      get :csg_petition_signature_count
      response.body.should == "0"
    end

    it "should look at petition signatures for count" do
      create(:petition_module, :id => 1392)
      create(:petition_signature, :content_module_id => 1392)

      get :csg_petition_signature_count
      response.body.should == "1"
    end
  end

  describe "#users" do
    before(:each) do
      create(:postcode_of_tw_office)
    end

    def post_agra_request(postcode, username = 'api', password = "8hsFCogjQfFZ", token = nil, categories = [], source = nil)
      data = {
          :slug => "title-2",
          :first_name => "richard",
          :last_name => "getup",
          :email => "richard@gmail.com",
          :postcode => postcode,
          :phone_number => "089987",
          :role => "creator",
          :categories => categories,
          :t => token,
          :source => source
      }

      request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials(username, password)

      post :users, {:data => data.to_json}
    end

    it "should create an action_taken UAE for new signer and set warehouse info" do
      user = create(:user)
      campaign = create(:campaign)
      push = create(:push, campaign: campaign)
      blast = create(:blast, push: push)
      email = create(:email, blast: blast)
      token = EmailTrackingToken.encode(user.id, email.id)
      

      post_agra_request("2000", "api", "8hsFCogjQfFZ", token)

      response.should be_success
      new_user = User.find_by_email('richard@gmail.com')
      agra_action = AgraAction.find_last_by_user_id(new_user.id)
      event_record = UserActivityEvent.find_last_by_user_id(new_user.id)
      event_record.activity.should == :action_taken
      event_record.user.should == new_user
      event_record.campaign.should == campaign
      event_record.push.should == push
      event_record.email.should == email
      event_record.user_response.should == agra_action
      event_record.source.should == 'cr_creator'
      event_record.public_stream_html.should == "<span class=\"name\">Richard</span> created Community Run campaign <a href='https://www.communityrun.org/petitions/title-2'>Title</a>"
      warehouse_data_should_include({user_id: new_user.id, email_id: email.id, token_user_id: user.id})
    end

    context "with a slug that is quarantined" do
      before do
        Setting.quarantined_controlshift_slugs = ['title-2', 'another slug']
        post_agra_request('2000')
      end

      it "should set any new members to be quarantined" do
        expect(User.find_by_email('richard@gmail.com')).to be_quarantined
      end

      it "should create an event" do
        expect(User.find_by_email('richard@gmail.com').user_activity_events.quarantines.where(source: 'cr').count).to eq(1)
      end

      it "should associate the slug with the event" do
        event = User.find_by_email('richard@gmail.com').user_activity_events.quarantines.first
        expect(event.user_response.slug).to eq('title-2')
      end
    end

    it "should set warehouse_data on existing users" do
      user = create(:user, :email=>'richard@gmail.com')
      post_agra_request("2000")
      warehouse_data_should_include({user_id: user.id, email_id: nil, token_user_id: nil})
    end

    it "should re-subscribe existing users" do
      user = create(:user, email:'richard@gmail.com', is_member:false, is_agra_member:false)
      post_agra_request("2000")
      user.reload
      user.is_member.should be true
      user.is_agra_member.should be true
    end

    it "should create an action_taken UAE record against the petition signer when no token" do
      post_agra_request("2000")
      check_agra_user_activity_event_created
    end

    context "with a token with an acquisition source" do
      let!(:acquisition_source){ create(:acquisition_source) }
      let!(:token){ EmailTrackingToken.encode_with_source(acquisition_source.id) }

      it "should record the acquisition_source against the subscription and event" do
        post_agra_request("2000", 'api', "8hsFCogjQfFZ", token)
        actions = User.find_by_email('richard@gmail.com').user_activity_events.where('acquisition_source_id is not null')
        expect(actions.count).to eq(2)
        actions.each do |action|
          expect(action.acquisition_source).to eq(acquisition_source)
        end
      end
    end
    
    def check_agra_user_activity_event_created
      response.should be_success
      new_user = User.find_by_email('richard@gmail.com')
      event_record = UserActivityEvent.find_last_by_user_id_and_activity(new_user.id, 'action_taken')
      event_record.should_not be_nil
      event_record.email_id.should be_nil
      event_record.user_response_type.should == AgraAction.name
    end

    it "should create an action_taken UAE record against the petition signer with invalid token" do
      post_agra_request("2000", "api", "8hsFCogjQfFZ", "lkjlkjljlkjlkjlkj")
      check_agra_user_activity_event_created
    end

    it "should able to receive the request post data" do
      post_agra_request("2000")
      response.should be_success
    end

    it "stores first 100 chars of source parameter in agra_actions" do
      post_agra_request("2000", 'api', '8hsFCogjQfFZ', nil, [], '1234567890'*200)
      response.should be_success
      agra_action = AgraAction.find_last_by_user_id(User.find_by_email('richard@gmail.com'))
      agra_action.source.should == '1234567890'*10
    end

    it "should fail when authentication is not provided" do
      post_agra_request("2000", '', '')
      response.status.should == 401
    end

    it "should fail when username is wrong" do
      post_agra_request("2000", 'api123', '8hsFCogjQfFZ')
      response.status.should == 401
    end

    it "should fail when password is wrong" do
      post_agra_request("2000", 'api', '1231')
      response.status.should == 401
    end

    it "should create a new user if he is not a existing user of Tijuana and response status with 201" do
      User.find_by_email("richard@gmail.com").should be nil
      post_agra_request("2000")
      response.status.should == 201
      users = User.where(:email => "richard@gmail.com")
      users.size.should eql 1
      user = users.first
      user[:email].should == "richard@gmail.com"
      user[:mobile_number].should == "089987"
    end

    it "should set the source as community_run" do
      User.find_by_email("richard@gmail.com").should be nil
      post_agra_request("2000")
      user = User.find_by_email("richard@gmail.com")
      uae = UserActivityEvent.find_by_source('cr')
      uae.activity.should == UserActivityEvent::Activity::SUBSCRIBED
      uae.user_id.should == user.id
    end

    context "with community run categories passed" do
      let!(:categories){ ['test', 'environment'] }

      it "should call user#save_with_source_info! with community run category details" do
        User.any_instance.should_receive(:save_with_source_info!).with(nil, nil, nil, 'cr', nil, community_run_categories: categories)
        post_agra_request("2000", "api", "8hsFCogjQfFZ", nil, categories)
      end
    end

    it "should welcome new users with community run email" do
      UserMailer.should_receive(:welcome_to_community_run).with(an_instance_of(User))
      post_agra_request("2000")
    end

    it "should not store user postcode if postcode is not from Australia" do
      post_agra_request("78787878")
      users = User.where(:email => "richard@gmail.com")
      users.first.postcode.should eql nil
    end

    it "should store correct user Australia postcode" do
      post_agra_request("2000")
      users = User.where(:email => "richard@gmail.com")
      users.first.postcode.number.should == "2000"
    end

    context "with existing user" do
      it "should not create a new user" do
        create(:user, :email => "richard@gmail.com")
        UserMailer.should_not_receive(:welcome_to_getup)
        UserMailer.should_not_receive(:welcome_to_community_run)
        post_agra_request("2000")
        response.status.should == 200
        User.where(:email => "richard@gmail.com").size.should eql 1
      end
    end

    it "should return response status 500 on error" do
      User.stub(:find_by_email) { raise "an error" }
      post_agra_request("2000")
      response.status.should == 500
    end

    it "should create one AgraAction record" do
      post_agra_request("2000")
      user = User.find_by_email("richard@gmail.com")
      agra_actions = AgraAction.where(:user_id => user.id)
      agra_actions.size.should eql 1
      action = agra_actions.first
      action[:user_id].should == user.id
      action[:slug].should == "title-2"
      action[:role].should == "creator"
    end
  end

  describe 'signing with facebook' do
    before :each do
      new_page = create(:page_with_parent)
      @page = Page.find(new_page.id)
      @petition = create(:petition_module)
      ContentModuleLink.create!(:page => @page, :content_module => @petition, :layout_container => :sidebar)

      @params = {
          :page_id => @page.friendly_id,
          :module_id => @petition.id,
          :facebook_id => 1234,
          :first_name => 'Bruce',
          :last_name => 'Wayne',
          :email => 'bruce@example.com',
          :suburb => 'Sydney'
      }
    end

    context 'invalid parameters' do
      it 'should raise exception when content module cannot be found' do
        @params[:module_id] = -1
        expect { post(:take_action_with_fb, @params) }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it 'should raise exception when page cannot be found' do
        @params[:page_id] = -1
        expect { post(:take_action_with_fb, @params) }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it 'should raise exception when email is invalid' do
        @params[:email] = 'bad_email'
        expect { post(:take_action_with_fb, @params) }.to raise_error(Exception, 'Validation failed: Email is invalid')
      end
    end

    it 'should redirect to the next page in the page sequence' do
      next_page = create(:page, page_sequence: @page.page_sequence, name: 'next page')
      post(:take_action_with_fb, @params).location.should == "/campaigns/dummy-campaign-name/dummy-page-sequence-name/next-page"
    end

    context '"last page URL" configured for the page sequence' do
      it 'should redirect to the "last page url"' do
        @page.page_sequence.last_page_url = 'http://test.example.com'
        @page.page_sequence.save!
        post(:take_action_with_fb, @params).location.should == 'http://test.example.com'
      end
    end

    context 'user attempts to sign more than once' do
      it 'should sign the petition once only' do
        post :take_action_with_fb, @params
        post :take_action_with_fb, @params
        user = User.find_by_email(@params[:email])
        signatures = PetitionSignature.find_all_by_user_id(user.id)
        signatures.count.should == 1
        signatures.first.content_module_id = @petition.id
        signatures.first.page_id = @page.id
      end
    end

    context 'user attempts to sign before previous request has been recorded' do
      it 'should redirect to the next page in the page sequence' do
        e = ActiveRecord::RecordNotUnique.new('blah', 'potato')
        User.any_instance.stub(:save_with_source_info!).and_raise(e)
        next_page = create(:page, page_sequence: @page.page_sequence, name: 'next page')
        post(:take_action_with_fb, @params).location.should == "/campaigns/dummy-campaign-name/dummy-page-sequence-name/next-page"
      end
    end

    it 'should set the source for the action event to "facebook"' do
      post :take_action_with_fb, @params
      user = User.find_by_email(@params[:email])
      uae = UserActivityEvent.where(user_id: user.id).where(activity: 'action_taken')
      uae.count.should == 1
      uae.first.source.should == 'facebook'
    end

    it 'should record the FB id' do
      post :take_action_with_fb, @params
      user = User.find_by_email(@params[:email])
      expect(FacebookUser.where(user_id: user.id, facebook_id: '1234').count).to eq(1)
    end

    context "with a source tracking token" do
      let!(:source){ create(:acquisition_source) }
      let!(:token){ EmailTrackingToken.encode_with_source(source.id) }
      it 'should record the acquisition source of the action' do
        @params[:t] = token
        post :take_action_with_fb, @params
        user = User.find_by_email(@params[:email])
        UserActivityEvent.where(user_id: user.id).where(activity: 'action_taken').where(acquisition_source_id: source.id).should be_exist
      end
    end

    context 'new user' do
      it 'should subscribe with "facebook" as source and receive welcome email' do
        UserMailer.should_receive(:welcome_to_getup).with(an_instance_of(User))
        post :take_action_with_fb, @params
        user = User.find_by_email(@params[:email])
        uae = UserActivityEvent.where(user_id: user.id).where(activity: 'subscribed')
        uae.count.should == 1
        uae.first.source.should == 'facebook'
      end

      context "on a page_sequence with welcome_email_disabled" do
        before{ @page.page_sequence.update_attributes!(welcome_email_disabled: true) }

        it "should not send a welcome email" do
          UserMailer.should_not_receive(:welcome_to_getup).with(an_instance_of(User))
          post :take_action_with_fb, @params
        end
      end

      context "with a source tracking token" do
        let!(:source){ create(:acquisition_source) }
        let!(:token){ EmailTrackingToken.encode_with_source(source.id) }

        it 'should record the acquisition source of the subscription' do
          @params[:t] = token
          post :take_action_with_fb, @params
          user = User.find_by_email(@params[:email])
          UserActivityEvent.where(user_id: user.id).where(activity: 'subscribed').where(acquisition_source_id: source.id).should be_exist
        end
      end
    end

    context 'existing user' do
      it "should not send welcome email" do
        UserMailer.should_not_receive(:welcome_to_getup)
        existing_user = create(:user, first_name: 'Bat', last_name: 'Man', suburb: 'Gotham City', email: 'bruce@example.com')
        post :take_action_with_fb, @params
      end

      it 'should not update existing attributes' do
        existing_user = create(:user, first_name: 'Bat', last_name: 'Man', suburb: 'Gotham City', email: 'bruce@example.com')
        post :take_action_with_fb, @params
        user = User.find(existing_user.id)
        user.first_name.should == 'Bat'
        user.last_name.should == 'Man'
        user.suburb.should == 'Gotham City'
      end

      it 'should update empty attributes' do
        existing_user = create(:user, first_name: nil, last_name: nil, suburb: nil, facebook_id: nil, email: 'bruce@example.com')
        post :take_action_with_fb, @params
        user = User.find(existing_user.id)
        user.first_name.should == 'Bruce'
        user.last_name.should == 'Wayne'
        user.suburb.should == 'Sydney'
        user.facebook_id.should == '1234'
      end
    end

    context 'thank you email configured' do
      before :each do
        existing_user = create(:user, email: 'bruce@example.com')
        ActionMailer::Base.deliveries = nil
      end

      it "queues an email if configured" do
        @page.update_attributes!(:send_thankyou_email => true, :thankyou_email_subject => "Thanks!", :thankyou_email_text => "You're great.")
        post :take_action_with_fb, @params
        ActionMailer::Base.should have(1).deliveries
        @email = ActionMailer::Base.deliveries.last
        @email.should deliver_to('bruce@example.com')
        @email.should have_subject(/Thanks!/)
        @email.should have_body_text(/You're great./)
      end

      it "does not queue when email is not configured" do
        @page.update_attributes!(:send_thankyou_email => false)
        post :take_action_with_fb, @params
        ActionMailer::Base.deliveries.should be_empty
      end

      it 'does not send on duplicate action exception' do
        @page.update_attributes!(:send_thankyou_email => true, :thankyou_email_subject => "Thanks!", :thankyou_email_text => "You're great.")
        post :take_action_with_fb, @params
        post :take_action_with_fb, @params
        ActionMailer::Base.should have(1).deliveries
        @email = ActionMailer::Base.deliveries.last
        @email.should have_subject(/Thanks!/)
      end
    end

    context "with quarantined page" do
      before{ @page.page_sequence.update_attributes!(quarantined: true) }

      it "should quarantine the user" do
        post :take_action_with_fb, @params
        expect(User.find_by_email(@params[:email])).to be_is_member
        expect(User.find_by_email(@params[:email])).to be_quarantined
      end

      it "should not send welcome email" do
        UserMailer.should_not_receive(:welcome_to_getup)
        post :take_action_with_fb, @params
      end

      it "should create a quarantined event" do
        post :take_action_with_fb, @params
        expect(User.find_by_email(@params[:email]).user_activity_events.quarantines.count).to eq(1)
      end
    end
  end

  context "#vision_survey_2014" do
    shared_context "it returns demographic data" do
      it "should return the user's demographic data" do
        json['name'].should == 'Jane'
        json['postcode'].should == '2000'
        json['suburb'].should == 'Sydney'
        json['state'].should == 'NSW'
        json['members_in_postcode'].should == 2000
        json['events']['climate_rallies'].should == 40
        json['events']['election_volunteers'].should == 300
        json['events']['election_booths'].should == 10
      end

      it_should_behave_like "it returns donor specific data"
    end

    shared_context "it returns donor specific data" do
      context "#recurring donor" do
        let!(:donation) { create(:recurring_donation, user: user, last_donated_at: Time.now) }

        it "should provide the correct greeting" do
          json['greeting'].should == 'core'
        end

        it "should set the next path" do
          json['next_path'].should == 'survey1'
        end
      end

      context "#one off donor" do
        let!(:donation) { create(:donation, user: user, last_donated_at: Time.now) }

        it "should provide the correct greeting" do
          json['greeting'].should == 'thanks'
        end

        it "should set the next path" do
          json['next_path'].should == 'survey2'
        end
      end

      context "#non-donor" do
        it "should provide the correct greeting" do
          json['greeting'].should == 'new'
        end

        it "should set the next path" do
          json['next_path'].should == 'survey3'
        end
      end
    end

    let(:postcode) { create(:postcode_of_tw_office) }
    let(:user) { create(:user, first_name: 'Jane', postcode: postcode, suburb: 'Sydney') }
    let!(:vision_survey_result_by_postcode) { create(:vision_survey_data_by_postcode, postcode: postcode) }

    context "with a user who filled out the survey" do
      before(:each) do
        @q3_priority_issue1 = create(:vision_survey_q3_priority_issue, name: 'climate')
        @q3_priority_issue2 = create(:vision_survey_q3_priority_issue, name: 'reef')
        @q3_priority_issue3 = create(:vision_survey_q3_priority_issue, name: 'indigenous')
        issues = [@q3_priority_issue1, @q3_priority_issue2, @q3_priority_issue3]
        @vision_survey_result = create(:vision_survey_result, user: user,
                                        vision_survey_q3_priority_issues: issues)

        @key = UserIdEncoder.encode(user)
      end

      let(:json) {
        get :vision_survey_2014, key: @key
        JSON.parse(response.body)
      }

      it "should specify that the user has filled in the survey" do
        json['completed_survey'].should be true
      end

      it_should_behave_like "it returns demographic data"
      it_should_behave_like "it returns donor specific data"

      it "should return the survey data" do
        json['q4_priority_issue'].should == 'climate'
        json['q3_priorities'][0].should == 'climate'
        json['q3_priorities'][1].should == 'reef'
        json['q3_priorities'][2].should == 'indigenous'
        json['q10_facebook']['uses'].should be true
        json['q10_facebook']['follow'].should be true
        json['q11_youtube']['uses'].should be false
        json['q11_youtube']['follow'].should be false
        json['q12_twitter']['uses'].should be false
        json['q12_twitter']['follow'].should be false
        json['q13_blogging']['uses'].should be false
        json['q13_blogging']['follow'].should be_falsey
        json['q14_google']['uses'].should be false
        json['q14_google']['follow'].should be false
        json['q18_transparency'].should == 'nimble'
      end
    end

    context 'with user who filled out survey with top priority as one of the bottom 3 priorities' do
      before(:each) do
        @q3_priority_issue1 = create(:vision_survey_q3_priority_issue, name: 'climate')
        @q3_priority_issue2 = create(:vision_survey_q3_priority_issue, name: 'reef')
        @q3_priority_issue3 = create(:vision_survey_q3_priority_issue, name: 'indigenous')
        issues = [@q3_priority_issue1, @q3_priority_issue2, @q3_priority_issue3]
        @vision_survey_result = create(:vision_survey_result, user: user,
                                        q4_priority_issue: 'super',
                                        vision_survey_q3_priority_issues: issues)

        @key = UserIdEncoder.encode(user)
      end

      let(:json) {
        get :vision_survey_2014, key: @key
        JSON.parse(response.body)
      }

      it "should return the survey data" do
        json['q4_priority_issue'].should == 'climate'
      end
    end

    context 'with a user who filled out the survey more than once' do
      before(:each) do
        @q3_priority_issue1 = create(:vision_survey_q3_priority_issue, name: 'climate')
        @q3_priority_issue2 = create(:vision_survey_q3_priority_issue, name: 'reef')
        @q3_priority_issue3 = create(:vision_survey_q3_priority_issue, name: 'indigenous')
        @q3_priority_issue4 = create(:vision_survey_q3_priority_issue, name: 'abc')
        @q3_priority_issue5 = create(:vision_survey_q3_priority_issue, name: 'privacy')
        @q3_priority_issue6 = create(:vision_survey_q3_priority_issue, name: 'tpp')
        @q3_priority_issue7 = create(:vision_survey_q3_priority_issue, name: 'safety-net')

        issues1 = [@q3_priority_issue1, @q3_priority_issue2, @q3_priority_issue3]
        @vision_survey_result1 = create(:vision_survey_result, user: user,
                                        vision_survey_q3_priority_issues: issues1)

        issues2 = [@q3_priority_issue3, @q3_priority_issue4, @q3_priority_issue5]
        @vision_survey_result2 = create(:vision_survey_result, user: user,
                                        vision_survey_q3_priority_issues: issues2)

        issues3 = [@q3_priority_issue5, @q3_priority_issue6, @q3_priority_issue7]
        @vision_survey_result3 = create(:vision_survey_result, user: user,
                                        vision_survey_q3_priority_issues: issues3)

        @key = UserIdEncoder.encode(user)
      end

      let(:json) {
        get :vision_survey_2014, key: @key
        JSON.parse(response.body)
      }

      it 'should specify that the user has filled in the survey' do
        json['completed_survey'].should be true
      end

      it_should_behave_like 'it returns demographic data'
      it_should_behave_like 'it returns donor specific data'

      it 'should return the survey data from the first result' do
        json['q3_priorities'][0].should == 'climate'
        json['q3_priorities'][1].should == 'reef'
        json['q3_priorities'][2].should == 'indigenous'
        json['q10_facebook']['uses'].should be true
        json['q10_facebook']['follow'].should be true
        json['q11_youtube']['uses'].should be false
        json['q11_youtube']['follow'].should be false
        json['q12_twitter']['uses'].should be false
        json['q12_twitter']['follow'].should be false
        json['q13_blogging']['uses'].should be false
        json['q13_blogging']['follow'].should be_falsey
        json['q14_google']['uses'].should be false
        json['q14_google']['follow'].should be false
        json['q18_transparency'].should == 'nimble'
      end
    end

    context "with user who has not filled out survey" do
      context "with a key" do
        it "should return 401" do
          new_user = create(:user)
          key = UserIdEncoder.encode(new_user)

          get :vision_survey_2014, key: key
          response.status.should == 401
          response.body.should == 'No valid key or token provided'
        end
      end

      context "with a token" do
        before do
          email = create(:email)
          @token = EmailTrackingToken.encode(user.id, email.id)
        end
        let(:json) {
          get :vision_survey_2014, t: @token
          JSON.parse(response.body)
        }

        it "should specify that the user has not filled in the survey" do
          json['completed_survey'].should be false
        end

        it_should_behave_like "it returns demographic data"
        it_should_behave_like "it returns donor specific data"
      end

      context "with a token but no matching postcode" do
        before do
          email = create(:email)
          user.postcode = create(:postcode, number: '1004')
          user.save!
          @token = EmailTrackingToken.encode(user.id, email.id)
        end
        let(:json) {
          get :vision_survey_2014, t: @token
          JSON.parse(response.body)
        }

        it "should specify that the user has not filled in the survey" do
          json['completed_survey'].should be false
        end

        it "should not return user's demographic data" do
          json['name'].should == 'Jane'
          json['suburb'].should == 'Sydney'
          json['postcode'].should be_nil
          json['state'].should be_nil
          json['members_in_postcode'].should be_nil
          json['events'].should be_empty
        end
        it_should_behave_like "it returns donor specific data"
      end


      context "without a token" do
        it "should return 401" do
            get :vision_survey_2014
            response.status.should == 401
            response.body.should == 'No valid key or token provided'
        end
      end
    end

    context "with user who does not have a postcode" do
      let(:user) { create(:user, first_name: 'Jane', postcode: nil, suburb: 'Sydney') }

      context "with user who has filled out survey" do
        before(:each) do
          @q3_priority_issue1 = create(:vision_survey_q3_priority_issue, name: 'climate')
          @q3_priority_issue2 = create(:vision_survey_q3_priority_issue, name: 'reef')
          @q3_priority_issue3 = create(:vision_survey_q3_priority_issue, name: 'indigenous')
          @issues = [@q3_priority_issue1, @q3_priority_issue2, @q3_priority_issue3]

          vision_survey_result = create(:vision_survey_result, user: user,
                                         vision_survey_q3_priority_issues: @issues)
          @key = UserIdEncoder.encode(user)
        end

        let(:json) {
          get :vision_survey_2014, key: @key
          JSON.parse(response.body)
        }

        it "should not return user's demographic data" do
          json['name'].should == 'Jane'
          json['suburb'].should == 'Sydney'
          json['postcode'].should be_nil
          json['state'].should be_nil
          json['members_in_postcode'].should be_nil
          json['events'].should be_empty
        end

        it_should_behave_like "it returns donor specific data"
      end
    end

    context 'with a user who does not have a suburb' do
      let(:user) { create(:user, first_name: 'Jane', postcode: postcode, suburb: nil) }

      context "with user who has filled out survey" do
        before(:each) do
          @q3_priority_issue1 = create(:vision_survey_q3_priority_issue, name: 'climate')
          @q3_priority_issue2 = create(:vision_survey_q3_priority_issue, name: 'reef')
          @q3_priority_issue3 = create(:vision_survey_q3_priority_issue, name: 'indigenous')
          @issues = [@q3_priority_issue1, @q3_priority_issue2, @q3_priority_issue3]

          vision_survey_result = create(:vision_survey_result, user: user,
                                         vision_survey_q3_priority_issues: @issues)
          @key = UserIdEncoder.encode(user)
        end

        let(:json) {
          get :vision_survey_2014, key: @key
          JSON.parse(response.body)
        }
        it "should return the user's demographic data" do
          json['name'].should == 'Jane'
          json['postcode'].should == '2000'
          json['suburb'].should be_nil
          json['state'].should == 'NSW'
          json['members_in_postcode'].should == 2000
          json['events']['climate_rallies'].should == 40
          json['events']['election_volunteers'].should == 300
          json['events']['election_booths'].should == 10
        end

        it_should_behave_like "it returns donor specific data"
      end
    end
  end

  describe "#tag_emails" do
    before do 
      @api_token = '123987sdfjh3498g8s'
      Setting["api_token"] = @api_token
      @user = User.create!(email: "test@example.com")
    end

    it "returns an error if no token supplied" do
      @request.headers['CONTENT_TYPE'] = "application/json"
      response = post :tag_emails, {tag: 'testipoptag', emails: ['test@example.com']}

      expect(response).to have_http_status(401)
    end

    it "returns an error if token empty" do 
      @request.headers.merge!({'CONTENT_TYPE' => "application/json", 'Auth-Token' => ''})

      response = post :tag_emails, {tag: 'testipoptag', emails: ['test@example.com']} 
      expect(response).to have_http_status(401)
    end

    it "returns an error if token incorrect" do 
      @request.headers.merge!({'CONTENT_TYPE' => "application/json", 'Auth-Token' => "this ain't the token!"})
      response = post :tag_emails, {tag: 'testipoptag', emails: ['test@example.com']}

      expect(response).to have_http_status(401)
    end

    it "adds the tag" do
      @request.headers.merge!({'CONTENT_TYPE' => "application/json", 'Auth-Token' => @api_token})
      response = post :tag_emails, {tag: 'testipoptag', emails: ['test@example.com']}

      expect(response).to have_http_status(200)
      expect(@user.tags.first.name).to eq('testipoptag')
    end

    it "doesn't insert new members" do
      @request.headers.merge!({'CONTENT_TYPE' => "application/json", 'Auth-Token' => @api_token})
      response = post :tag_emails, {tag: 'testipoptag', emails: ['test-new@example.com']}

      expect(response).to have_http_status(200)
      expect(User.find_by(email: 'test-new@example.com')).to be_nil
    end

    it "returns correct error if missing params" do
      @request.headers.merge!({'CONTENT_TYPE' => "application/json", 'Auth-Token' => @api_token})
      response = post :tag_emails, {tagger: 'testipoptag', emails: ['test-new@example.com']}

      expect(response).to have_http_status(400)
      expect(response.body).to eq({status: "Rejected", reason: "Missing params"}.to_json)
    end

    it "returns correct error if too long tag" do
      @request.headers.merge!({'CONTENT_TYPE' => "application/json", 'Auth-Token' => @api_token})
      response = post :tag_emails, {tag: (0..300).map{|n| 'a'}.join, emails: ['test-new@example.com']}

      expect(response).to have_http_status(400)
      expect(response.body).to eq({status: "Rejected", reason: "Tag max length is 255"}.to_json)
    end

    it "returns correct error if too many emails" do
      @request.headers.merge!({'CONTENT_TYPE' => "application/json", 'Auth-Token' => @api_token})
      response = post :tag_emails, {tag: 'testipoptag', emails: (1..2000).map{|x| "test#{x}@gmail.com"}}

      expect(response).to have_http_status(400)
      expect(response.body).to eq({status: "Rejected", reason: "Max 1000 emails may be submitted at once. Batch your calls if you have more"}.to_json)
    end
  end

  describe "#page_sequences" do
    it "doesn't return any matching page sequences" do
      response = get :page_sequences, {pillar: 'environment'}

      page_sequences = JSON.parse(response.body)
      expect(page_sequences.length).to eq(0)
    end

    it "returns correct error if missing params" do
      response = get :page_sequences, {pillar: 'plimpool'}

      expect(response).to have_http_status(400)
      expect(response.body).to eq({status: "Rejected", reason: "invalid key"}.to_json)
    end

  end


  describe "#electoral_target" do
    before do 
      @api_token = '123987sdfjh3498g8s'
      Setting["api_token"] = @api_token
      @jurisdiction = Jurisdiction.create!(name: 'Federal', code: 'FEDERAL')
      @postcode1 = Postcode.create!(number: '1000', state: 'QLD', longitude: 100.100, latitude: -30.300)
      @postcode2 = Postcode.create!(number: '0900', state: 'NT', longitude: 100.100, latitude: -30.300)
      @party1 = Party.create!(name: 'Imperial Fleet', abbreviation: 'IMP', jurisdiction_id: @jurisdiction.id)
      @party2 = Party.create!(name: 'Atheist\'s Alliance', abbreviation: 'AAP', jurisdiction_id: @jurisdiction.id)
      @party3 = Party.create!(name: 'Nihilist\'s Round Table', abbreviation: 'NRT', jurisdiction_id: @jurisdiction.id)
      @party4 = Party.create!(name: 'Toffe Windors', abbreviation: 'TWS', jurisdiction_id: @jurisdiction.id)
      @electorate1 = @postcode1.electorates.create!(name: 'Old World', jurisdiction_id: @jurisdiction.id)
      @electorate2 = @postcode1.electorates.create!(name: 'New World', jurisdiction_id: @jurisdiction.id)
      @electorate3 = @postcode2.electorates.create!(name: 'Northern Territory', jurisdiction_id: @jurisdiction.id)
      @region1 = @postcode1.regions.create!(name: 'State', jurisdiction_id: @jurisdiction.id)
      @region2 = @postcode1.regions.create!(name: 'Territory', jurisdiction_id: @jurisdiction.id)
      make_electorate_postcode_populous(@postcode1, @electorate1, 1000)
      make_electorate_postcode_populous(@postcode1, @electorate2, 2000)
      @mp1 = Mp.create!(first_name: 'Her', last_name: 'Majesty', office_phone: '(02) 3245 2352', parliament_phone: '(02) 3245 2352', electorate_id: @electorate1.id, email: 'hm@hm.uk', office_state: 'NSW', office_postcode: '1000', party_id: @party4.id)
      @mp2 = Mp.create!(first_name: 'Public', last_name: 'Servant', office_phone: '02-9878-6785', parliament_phone: '02-9878-6785', electorate_id: @electorate2.id, email: 'for@the.people', office_state: 'NSW', office_postcode: '1000', party_id: @party2.id)
      @mp3 = Mp.create!(first_name: 'Territory', last_name: 'Rep', office_phone: '02-9878-6785', parliament_phone: '02-9878-6785', electorate_id: @electorate3.id, email: 'for@the.people', office_state: 'NSW', office_postcode: '1000', party_id: @party2.id)
      @senator1 = Senator.create!(first_name: 'Base', last_name: 'Ponderer', office_phone: '02-9878-6785', parliament_phone: '02-9878-6785', region_id: @region1.id, email: 'for@the.people', office_state: 'NSW', office_postcode: '1000', party_id: @party1.id)
      @senator2 = Senator.create!(first_name: 'Thinks', last_name: 'Deeply', office_phone: '02-9878-6785', parliament_phone: '02-9878-6785', region_id: @region2.id, email: 'for@the.people', office_state: 'NSW', office_postcode: '1000', party_id: @party2.id)
    end

    context "with no party specified" do
      it "returns electoral targets" do
        @request.headers.merge!({'CONTENT_TYPE' => "application/json", 'Auth-Token' => @api_token})
        response = post :electoral_target, {postcode: '1000', jurisdiction: 'FEDERAL'}
        expect(response).to have_http_status(200)
        electoral_targets = JSON.parse(response.body)
        expect(electoral_targets.length).to eq(2)
        expect(electoral_targets[0].has_key?('name')).to eq(true)
        expect(electoral_targets[0].has_key?('phone_number')).to eq(true)
        expect(electoral_targets[0].has_key?('electorate')).to eq(true)
        expect(electoral_targets[1]["name"]).to eq('Her Majesty')
        expect(electoral_targets[0]["name"]).to eq('Public Servant')
        expect(electoral_targets[1]["electorate"]).to eq('Old World')
        expect(electoral_targets[0]["electorate"]).to eq('New World')
        expect(electoral_targets[1]["phone_number"]).to eq('61232452352')
        expect(electoral_targets[0]["phone_number"]).to eq('61298786785')
      end
    end

    context "with a valid mp party specified" do
      it "returns electoral targets" do
        @request.headers.merge!({'CONTENT_TYPE' => "application/json", 'Auth-Token' => @api_token})
        response = post :electoral_target, {postcode: '1000', jurisdiction: 'FEDERAL', parties: ['TWS', 'AAP']}
        expect(response).to have_http_status(200)
        electoral_targets = JSON.parse(response.body)
        expect(electoral_targets.length).to eq(2)
        expect(electoral_targets[0].has_key?('name')).to eq(true)
        expect(electoral_targets[0].has_key?('phone_number')).to eq(true)
        expect(electoral_targets[0].has_key?('electorate')).to eq(true)
        expect(electoral_targets[1]["name"]).to eq('Her Majesty')
        expect(electoral_targets[0]["name"]).to eq('Public Servant')
        expect(electoral_targets[1]["electorate"]).to eq('Old World')
        expect(electoral_targets[0]["electorate"]).to eq('New World')
        expect(electoral_targets[1]["phone_number"]).to eq('61232452352')
        expect(electoral_targets[0]["phone_number"]).to eq('61298786785')
      end

      context 'with fallback option' do
        before do
          @request.headers.merge!({'CONTENT_TYPE' => "application/json", 'Auth-Token' => @api_token})
          response = post :electoral_target, {postcode: '1000', jurisdiction: 'FEDERAL', parties: ['AAP']}
        end

        it 'should return a result for every electorate matching the postcode' do
            expect(response).to have_http_status(200)
            electoral_targets = JSON.parse(response.body)
            expect(electoral_targets.length).to eq(2)
        end

        context 'with an electorate with an MP matching the party' do
          it 'should return the MPs details' do
            expect(response).to have_http_status(200)
            electoral_targets = JSON.parse(response.body)
            expect(electoral_targets[0].has_key?('name')).to eq(true)
            expect(electoral_targets[0].has_key?('phone_number')).to eq(true)
            expect(electoral_targets[0].has_key?('electorate')).to eq(true)
            expect(electoral_targets[0]["name"]).to eq('Public Servant')
            expect(electoral_targets[0]["electorate"]).to eq('New World')
            expect(electoral_targets[0]["phone_number"]).to eq('61298786785')
          end
        end

        context 'with an electorate with an MP NOT matching the party' do
          it 'should fallback to using a random senator in the same state' do
            expect(response).to have_http_status(200)
            electoral_targets = JSON.parse(response.body)
            expect(electoral_targets[1].has_key?('name')).to eq(true)
            expect(electoral_targets[1].has_key?('phone_number')).to eq(true)
            expect(electoral_targets[1].has_key?('electorate')).to eq(true)
            expect(electoral_targets[1]["name"]).to eq('Thinks Deeply')
            expect(electoral_targets[1]["electorate"]).to eq('Old World')
            expect(electoral_targets[1]["senator"]).to eq(true)
            expect(electoral_targets[1]["phone_number"]).to eq('61298786785')
          end
        end

        context 'with an electorate with a postcode with a leading zero' do
          before do
            response = post :electoral_target, {postcode: '0900', jurisdiction: 'FEDERAL', parties: ['AAP']}
          end
          it 'should return the MPs details' do
            expect(response).to have_http_status(200)
            electoral_targets = JSON.parse(response.body)
            expect(electoral_targets[0].has_key?('name')).to eq(true)
            expect(electoral_targets[0].has_key?('phone_number')).to eq(true)
            expect(electoral_targets[0].has_key?('electorate')).to eq(true)
            expect(electoral_targets[0]["name"]).to eq('Territory Rep')
            expect(electoral_targets[0]["electorate"]).to eq('Northern Territory')
            expect(electoral_targets[0]["senator"]).to eq(false)
            expect(electoral_targets[0]["phone_number"]).to eq('61298786785')
          end
        end
      end
    end

    it "returns correct error if missing params" do
      @request.headers.merge!({'CONTENT_TYPE' => "application/json", 'Auth-Token' => @api_token})
      response = post :electoral_target, {postcode: '1000'}
      expect(response).to have_http_status(400)
      expect(response.body).to eq({status: "Rejected", reason: "Missing params"}.to_json)
    end

    it "returns correct error if postcode nonexistant" do
      @request.headers.merge!({'CONTENT_TYPE' => "application/json", 'Auth-Token' => @api_token})
      response = post :electoral_target, {postcode: '0000', jurisdiction: 'FEDERAL'}
      expect(response).to have_http_status(400)
      expect(response.body).to eq({status: "Rejected", reason: "No Matching Postcode"}.to_json)
    end

    it "returns correct error if party nonexistant" do
      @request.headers.merge!({'CONTENT_TYPE' => "application/json", 'Auth-Token' => @api_token})
      response = post :electoral_target, {postcode: '1000', jurisdiction: 'FEDERAL', parties: ['XXX']}
      expect(response).to have_http_status(400)
      expect(response.body).to eq({status: "Rejected", reason: "No Matching Party"}.to_json)
    end

  end

  describe "#transparency_stats" do
    before do
      @campaign = Campaign.create!(name: "democracy", accounts_key: "democracy")
      @page_sequence = PageSequence.create!(campaign_id: @campaign.id, name: "test", title: "hidden test", blurb: "yada", options: {:facebook_image => "test.png"})
      @page = Page.create!(name: "Blerg", page_sequence_id: @page_sequence.id)
      @user = User.create!(email: "test@test.test", first_name: "test")
      @content_module = ContentModule.create!(type: 'DonationModule')
      @donation = Donation.create!(amount_in_cents: 5555, user_id: @user.id, content_module_id: @content_module.id, page_id: @page.id, payment_method: 'credit_card', name_on_card: "test", card_number: "1234", card_cvv: "123", card_expiry_month: "12", card_expiry_year: "2020", frequency: "one_off")
      Stats::TransparencyStats.new.update
    end

    it "returns transparency stats" do
      response = get :transparency_stats

      expect(response).to have_http_status(200)
      transparency_stats = JSON.parse(response.body)
      transparency_stats.each do |value|
        if value["name"] == 'New Members'
          expect(value["day"]).to eq(1)
        end
        if value["name"] == 'First-time Donors'
          expect(value["day"]).to eq(1)
        end
      end
    end

  end

  describe 'CORS' do
    before { request.headers.merge!({origin: origin}) }
    let!(:response) { get :transparency_stats }

    [
      'https://showcase.getup.org.au',
      'http://legit-raven.cloudvent.net',
      'https://legit-raven.cloudvent.net',
      'https://app.cloudcannon.com',
      'http://localhost:9000',
      'http://127.0.0.1:3000',
      'http://0.0.0.0:5000',
      'https://showcase.getup.org.au/',
      'http://localhost:9000/',
    ].each do |origin|
      context "with origin as #{origin} (allowed)" do
        let(:origin) { origin }

        it 'sets the proper headers' do
          expect(response.headers['Access-Control-Allow-Origin']).to eq(origin)
        end
      end
    end

    [
      'http://www.example.com',
      'https://www.example.com',
      'http://www.example.com/',
      'https://www.example.com/',
      'http://www.example.com:1234',
      'https://www.example.com:1234/',
      'https://legit-raven.cloudvent.net.example.com',
    ].each do |origin|
      context "with origin as #{origin} (not allowed)" do
        let(:origin) { origin }

        it 'does not set the headers' do
          expect(response.headers['Access-Control-Allow-Origin']).to be_nil
        end
      end
    end
  end

  def make_electorate_postcode_populous(postcode, electorate, population)
    ActiveRecord::Base.connection.execute("update electorates_postcodes set population=#{population} where electorate_id = #{electorate.id} and postcode_id = #{postcode.id}")
  end

end
