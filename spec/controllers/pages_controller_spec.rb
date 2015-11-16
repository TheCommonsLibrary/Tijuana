require File.expand_path(File.dirname(__FILE__) + "../../spec_helper")

describe PagesController do
  include ApplicationHelper
  include VanityTestHelper

  before do
    Rails.cache.clear
  end

  describe "redirecting when page sequence has expired" do
    describe "and expired_page_redirect feature toggled on" do
      describe "by expired boolean field" do
        before(:each) do
          @page = create(:page_with_parent, :name => "expired")
          @page_sequence = @page.page_sequence
          @page_sequence.update_attributes!(:expired => true)
          @page_sequence_fid = @page_sequence.friendly_id
          @campaign_fid = @page_sequence.campaign.friendly_id
          Setting.create!(:key => 'expired_page_redirect', :value => '1')
          @website_pillar_uri = 'https://showcase.getup.org.au/campaings-hub'
          Setting.create!(:key => 'website_pillar_uri', :value => @website_pillar_uri)
        end

        describe "with no page sequence to redirect to" do
          describe "and campaign assigned to pillar" do
            it "should redirect offsite to website pillar page attributed to campaigns pillar" do
              get :show, :campaign_id => @campaign_fid, :page_sequence_id => @page_sequence_fid, :id => "expired"
              expect(response).to be_redirect
              expect(response.location()).to eq("#{@website_pillar_uri}/#{@page_sequence.campaign.pillar.downcase}")
            end

            describe "and pillar has non-uri characters" do
              before{ @page_sequence.campaign.update_attributes!(accounts_key: 'Economic Fairness') }
              it "should redirect offsite to the escaped website pillar page" do
                get :show, :campaign_id => @campaign_fid, :page_sequence_id => @page_sequence_fid, :id => "expired"
                expect(response).to be_redirect
                expect(response.location()).to eq("#{@website_pillar_uri}/economic-fairness")
              end
            end
          end
          describe "and campaign not assigned to pillar" do
            before(:each) do
              @page_sequence.campaign.update_attributes!(:accounts_key => nil)
            end
            it "should redirect offsite to website hub page" do
              get :show, :campaign_id => @campaign_fid, :page_sequence_id => @page_sequence_fid, :id => "expired"
              expect(response).to be_redirect
              expect(response.location()).to eq("#{@website_pillar_uri}")
            end
          end
        end

        describe "with page sequence to redirect to" do
          before(:each) do
            new_page = create(:page_with_parent, :name => "not expired")
            redirect_page_sequence = PageSequence.find(new_page.page_sequence.id)
            @page_sequence.update_attributes!(:expired_redirect_page_sequence_id => redirect_page_sequence.id)
            @redirect_page_sequence_uri = friendly_path(redirect_page_sequence.landing_page) unless redirect_page_sequence.nil? || redirect_page_sequence.landing_page.nil?
          end

          it "should redirect to attributed redirect page_sequence_id" do
            get :show, :campaign_id => @campaign_fid, :page_sequence_id => @page_sequence_fid, :id => "expired"
            expect(response).to be_redirect
            expect(response.location()).to eq("http://test.host#{@redirect_page_sequence_uri}")
          end
        end
      end
      describe "by expires_at datetime field" do
        before(:each) do
          @page = create(:page_with_parent, :name => "expired")
          @page_sequence = @page.page_sequence
          @page_sequence.update_attributes!(:expires_at => DateTime.now - 1.days)
          @page_sequence_fid = @page_sequence.friendly_id
          @campaign_fid = @page_sequence.campaign.friendly_id
          Setting.create!(:key => 'expired_page_redirect', :value => '1')
          @website_pillar_uri = 'https://showcase.getup.org.au/campaings-hub'
          Setting.create!(:key => 'website_pillar_uri', :value => @website_pillar_uri)
        end
        it "should redirect" do
          get :show, :campaign_id => @campaign_fid, :page_sequence_id => @page_sequence_fid, :id => "expired"
          expect(response).to be_redirect
        end
      end
    end
  end

  describe "#show user from token" do
    before(:each) do
      @page = create(:page_with_parent, :name => "showpage")
      @token_user = create(:user, email: 'test1@email.com')
      @token = EmailTrackingToken.encode(@token_user.id, create(:email).id)
    end

    it "tracking token user should be loaded with valid token" do
      get :show, :campaign_id => @page.page_sequence.campaign.friendly_id,
                 :page_sequence_id => @page.page_sequence.friendly_id , :id => "showpage",
                 :t => @token
      assigns(:token_user).should == @token_user
    end

    it "user should be nil if no token" do
      get :show, :campaign_id => @page.page_sequence.campaign.friendly_id,
                 :page_sequence_id => @page.page_sequence.friendly_id , :id => "showpage"
      assigns(:token_user).should be_nil
    end
  end

  describe "#show user from token with acquisition source" do
    before(:each) do
      @page = create(:page_with_parent, :name => "showpage")
      @token_user = create(:user, email: 'test1@email.com')
      @acquisition_source = create(:acquisition_source)
      @token = EmailTrackingToken.encode_with_source(@acquisition_source.id)
    end

    it "should handle the token ok" do
      get :show, :campaign_id => @page.page_sequence.campaign.friendly_id,
                 :page_sequence_id => @page.page_sequence.friendly_id , :id => "showpage",
                 :t => @token
      response.should be_success
    end
  end

  describe "#show user with no token but utm parameters" do
    let!(:page) { create(:page_with_parent, name: 'showpage') }
    def show_with_utm_params
      get :show, campaign_id: page.page_sequence.campaign.friendly_id,
                 page_sequence_id: page.page_sequence.friendly_id , id: "showpage",
                 utm_campaign: 'blast-2018-04-04!!', utm_source: 'id', utm_medium: 'email'
    end
    before{ show_with_utm_params }

    specify{ response.should be_success }

    it 'should create an acquisition source using the parameters' do
      expect(AcquisitionSource.where({
        name: 'blast-2018-04-04',
        source: 'id',
        medium: 'email',
        generated: true
      }).count).to eq(1)
    end

    it 'should use the token from the utm based acquisition source' do
      expect(TrackingTokenLookup.new(assigns(:token)).acquisition_source)
        .to eq(AcquisitionSource.first)
    end

    context 'called with an existing combination of utm parameters' do
      before{ show_with_utm_params }
      it 'should resuse the acquisition source' do
        expect(AcquisitionSource.where({
          name: 'blast-2018-04-04',
          source: 'id',
          medium: 'email',
          generated: true
        }).count).to eq(1)
      end
    end

    context 'with views rendered' do
      let!(:petition){ create(:petition_module) }
      let!(:content_module_link){ ContentModuleLink.create!(page: page, content_module: petition, layout_container: :sidebar) }
      render_views
      before{ show_with_utm_params }

      it 'should use the new token in the page' do
        response.body.should =~ /input type="hidden" name="t" value="#{assigns[:token]}"/
      end
    end
  end

  describe "redirecting to updated URLs when things are renamed" do
    before(:each) do
      @page = create(:page_with_parent, :name => "Original Name")
      @ps = @page.page_sequence.friendly_id
      @cam = @page.page_sequence.campaign.friendly_id
      @page.name = "New Name"
      @page.save!
    end

    it "render the page even if the name has changed" do
      get :show, :campaign_id => @cam, :page_sequence_id => @ps, :id => "original-name"
      expect(response).to be_redirect
    end

    it "should render 404 page when page not found" do
      get :show, :campaign_id => "nop", :page_sequence_id => "nop", :id => "nop"
      response.status.should eql 404
      expect(response).to render_template(:file => "#{Rails.root}/public/404.html")
    end
  end

  describe "#action_taken" do
    let!(:page){ create(:page_with_parent, :required_user_details => {:first_name => :required}) }
    let!(:petition){ create(:petition_module) }
    let!(:content_module_link){ ContentModuleLink.create!(:page => page, :content_module => petition, :layout_container => :main_content) }

    def action_params(user_params)
      {
        :module_id => petition.id,
        :user => user_params,
        :campaign_id => page.page_sequence.campaign.friendly_id,
        :page_sequence_id => page.page_sequence.friendly_id,
        :id => page.id,
        petition_signature: {}
      }
    end

    context "with a page that is quarantined" do
      before{ page.page_sequence.update_attributes!(quarantined: true) }

      context "with a new member" do
        before{ post :take_action, action_params({email: "bruce@example.com", is_member: '1', first_name: 'Bruce'}) }

        it "should set them to be quarantined" do
          expect(User.find_by_email('bruce@example.com')).to be_is_member
          expect(User.find_by_email('bruce@example.com')).to be_quarantined
        end

        it "should create an event" do
          expect(User.find_by_email('bruce@example.com').user_activity_events.quarantines.count).to eq(1)
        end
      end

      context "with an existing subscribed member" do
        let!(:existing_member){ create(:user) }

        it "should NOT set them to be low volume" do
          post :take_action, action_params({email: existing_member.email, is_member: '1', first_name: 'Bruce'})
          existing_member.reload
          expect(existing_member).to be_is_member
        end
      end
    end

    context "a AppConstants.mautic_auth set and a mautic id on the content module" do
      let!(:mautic_auth) { 'Basic 1' }
      let!(:mtc_id_cookie) { 1 }
      let!(:mautic_url) { "https://#{AppConstants.mautic_domain}/form/submit" }
      before do
        allow(AppConstants).to receive(:mautic_auth).and_return(mautic_auth)
        petition.update_attributes!(mautic_id: 123)
      end

      context 'with a mtc_id cookie set', delay_jobs: false do
        it 'should submit a request to mautic and pass the cookie' do
          cookies[:mtc_id] = mtc_id_cookie
          stub_request(:post, mautic_url).and_return(status: 200)
          post :take_action, action_params({email: "bruce@example.com", is_member: '1', first_name: 'Bruce'})
          expect(WebMock).to have_requested(:post, mautic_url).with {|req|
            req.headers['Cookie'] == "mtc_id=#{mtc_id_cookie}"
          }
        end
      end

    end
  end

  describe "welcome email on #action_taken" do
    before(:each) do
      @page = create(:page_with_parent, :required_user_details => {:first_name => :required})
      @petition = create(:petition_module)
      ContentModuleLink.create!(:page => @page, :content_module => @petition, :layout_container => :main_content)
    end

    def action_params(user_params)
      {
        :module_id => @petition.id,
        :user => user_params,
        :campaign_id => @page.page_sequence.campaign.friendly_id,
        :page_sequence_id => @page.page_sequence.friendly_id,
        :id => @page.id,
        petition_signature: {}
      }
    end

    context "joining on a page_sequence with welcome_email_disabled" do
      before do
        @page.page_sequence.update_attributes!(welcome_email_disabled: true)
      end
     
      it "should disable the welcome email" do
        UserMailer.should_not_receive(:welcome_to_getup)
        post :take_action, action_params({:email => "bruce@example.com", :is_member=>'1', first_name: 'Bruce'})
      end
    end

    context "for existing non-member" do
      before(:each) do
        create(:user, :email => 'bruce@example.com', :is_member=>false)
      end

      it "does not send when takes action and does not join" do
        UserMailer.should_not_receive(:welcome_to_getup)
        post :take_action, action_params({:email => "bruce@example.com", :is_member=>'0', first_name: 'Bruce'})
      end

      it "does not send when cannot take action due to error" do
        UserMailer.should_not_receive(:welcome_to_getup)
        post :take_action, action_params({:email => "bruce@example.com", :is_member=>'1'})
      end

      it "sends when takes action and joins" do
        UserMailer.should_receive(:welcome_to_getup)
        post :take_action, action_params({email:"bruce@example.com", is_member:'1', first_name: 'Bruce'})
      end
    end

    context "for existing member" do
      before(:each) do
        create(:user, :email => 'bruce@example.com', :is_member=>true)
      end

      it "does not send when takes action and does not join again" do
        UserMailer.should_not_receive(:welcome_to_getup)
        post :take_action, action_params({:email => "bruce@example.com", :is_member=>'0', first_name: 'Bruce'})
      end

      it "does not send when cannot take action due to error" do
        UserMailer.should_not_receive(:welcome_to_getup)
        post :take_action, action_params({:email => "bruce@example.com", :is_member=>'1'})
      end

      it "does not send when takes action and opts to join" do
        UserMailer.should_not_receive(:welcome_to_getup)
        post :take_action, action_params({email:"bruce@example.com", is_member:'1', first_name: 'Bruce'})
      end
    end

    context "for new member" do
      it "sends when joins completes action" do
        UserMailer.should_receive(:welcome_to_getup)
        post :take_action, action_params({email:"bruce@example.com", is_member:'1', first_name: 'Bruce'})
      end

      it "sends when joins cannot complete action due to error" do
        UserMailer.should_receive(:welcome_to_getup)
        post :take_action, action_params({email:"bruce@example.com", is_member:'1'})
      end

      it "does not send when opts out of joining and completes action" do
        UserMailer.should_not_receive(:welcome_to_getup)
        post :take_action, action_params({email:"bruce@example.com", is_member:'0', first_name: 'Bruce'})
      end

      it "does not send when opts out of joining and cannot complete action due to error" do
        UserMailer.should_not_receive(:welcome_to_getup)
        post :take_action, action_params({email:"bruce@example.com", is_member:'0'})
      end
    end

    context "with quarantined page" do
      before{ @page.page_sequence.update_attributes!(quarantined: true) }

      it "should not send welcome email to new users" do
        UserMailer.should_not_receive(:welcome_to_getup)
        post :take_action, action_params({email:"new@user.com", is_member:'1'})
      end
      
      it "should not send welcome email to existing users" do
        create(:user, email: 'existing@member.com')
        UserMailer.should_not_receive(:welcome_to_getup)
        post :take_action, action_params({email:"existing@member.com", is_member:'1'})
      end

      it "should not send welcome email to users who have not requested to join" do
        UserMailer.should_not_receive(:welcome_to_getup)
        post :take_action, action_params({email:"existing@member.com", is_member:'0'})
      end
    end
  end

  describe "finding or creating the user" do

    it "creates new user on the fly with all required details" do
      Postcode.create!(:number => "2060", :latitude => -33.837687, :longitude => 151.207323)
      page = create(:page_with_parent, :required_user_details => {:first_name => :required})
      petition = create(:petition_module)
      ContentModuleLink.create!(:page => page, :content_module => petition, :layout_container => :sidebar)

      params = {
        :module_id => petition.id,
        :user => {
          :first_name => "Bruce",
          :email => 'bruce@example.com',
          :postcode_number => "2060",
          :is_member => '0'
        },
        :campaign_id => page.page_sequence.campaign.friendly_id,
        :page_sequence_id => page.page_sequence.friendly_id,
        :id => page.friendly_id,
        petition_signature: {}
      }
      post :take_action, params
      assigns(:user).should be_persisted
      assigns(:user).email.should == 'bruce@example.com'
      assigns(:user).encrypted_password.should be_nil
      assigns(:user).postcode.number.should == "2060"
    end

    it "finds the appropriate user by email address" do
      page = create(:page_with_parent, :required_user_details => {:first_name => :required})
      petition = create(:petition_module)
      ContentModuleLink.create!(:page => page, :content_module => petition, :layout_container => :main_content)
      create(:user, :email => 'Someone.else@example.com')
      user = create(:user, :email => 'BRUCE@example.com')

      User.find(:all, :conditions => ['lower(email) = ?', 'bruce@example.com']).size.should eql(1)

      params = {
        :module_id => petition.id,
        :user => {:email => "bruce@example.com"},
        :campaign_id => page.page_sequence.campaign.friendly_id,
        :page_sequence_id => page.page_sequence.friendly_id,
        :id => page.id,
        petition_signature: {}
      }
      post :take_action, params
      assigns(:user).should eql(user)
    end

    it "creates new user on the fly without all required details" do
      page = create(:page_with_parent, :required_user_details => {:first_name => :required})
      petition = create(:petition_module)
      ContentModuleLink.create!(:content_module => petition, :page => page, :layout_container => :sidebar)

      params = {
        :module_id => petition.id,
        :user => {:email => 'bruce@gomez.com', :is_member => "false"},
        :campaign_id => page.page_sequence.campaign.friendly_id,
        :page_sequence_id => page.page_sequence.friendly_id,
        :id => page.id,
        petition_signature: {}
      }
      post :take_action, params

      user = User.find_by_email(params[:user][:email])
      user.should_not be_nil
      user.first_name.should be_nil
      user.is_member.should be false
      user.encrypted_password.should be_nil


    end

    it 'should display success message when user with duplicate email exception is raised' do
      page_with_parent = create(:page_with_parent, :required_user_details => {:first_name => :required})
      page = create(:page, :name => 'test', :page_sequence => page_with_parent.page_sequence)
      page_with_parent.page_sequence.pages << page
      petition = create(:petition_module)
      ContentModuleLink.create!(:content_module => petition, :page => page_with_parent, :layout_container => :sidebar)
      params = {
        :module_id => petition.id,
        :user => {:email => 'bruce@gomez.com', :is_member => 'false', :first_name => 'Nat'},
        :campaign_id => page_with_parent.page_sequence.campaign.friendly_id,
        :page_sequence_id => page_with_parent.page_sequence.friendly_id,
        :id => page_with_parent.id,
        petition_signature: {}
      }
      post :take_action, params
      e = ActiveRecord::RecordNotUnique.new('blah', 'potato')
      User.any_instance.stub(:validate_and_always_save_email).and_raise(e)
      post :take_action, params
      response.should redirect_to '/campaigns/dummy-campaign-name/dummy-page-sequence-name/test'
    end

    it "take_action should not allow is_admin to be set" do
      page = create(:page_with_parent, :required_user_details => {:first_name => :required})
      petition = create(:petition_module)
      ContentModuleLink.create!(:content_module => petition, :page => page, :layout_container => :sidebar)

      params = {
        :module_id => petition.id,
        :user => {:email => 'bruce@gomez.com', :is_member => "false", :is_admin => "true"},
        :campaign_id => page.page_sequence.campaign.friendly_id,
        :page_sequence_id => page.page_sequence.friendly_id,
        :id => page.id,
        petition_signature: {}
      }
      post :take_action, params

      user = User.find_by_email(params[:user][:email])
      user.should_not be_nil
      user.is_admin.should be false
      user.encrypted_password.should be_nil
    end
  end

  describe "with the tracking token from an acqusition source" do
    without_transactional_fixtures do
      it "should create a user activity event with the source encoded" do
        with_push_table do
          token_user = create(:user, email: 'test1@email.com')
          user = create(:user, email: 'test2@email.com')
          acquisition_source = create(:acquisition_source)
          token = EmailTrackingToken.encode_with_source(acquisition_source.id)

          page = create(:page_with_parent)
          petition = create(:petition_module)
          create(:content_module_link, :content_module => petition, :page => page, :layout_container => :sidebar)

          params = {
            :module_id => petition.id,
            :user => {:email => user.email},
            :campaign_id => page.page_sequence.campaign.friendly_id,
            :page_sequence_id => page.page_sequence.friendly_id,
            :id => page.id,
            :t => token,
            petition_signature: {}
          }
          post :take_action, params

          uae = UserActivityEvent.find_last_by_user_id(user.id)
          expect(uae.acquisition_source).to eq(acquisition_source)
        end
      end

      context "with a new user" do
        it "should record the subscription user activity event with the acquisition source" do
          new_email = 'test2@email.com'
          acquisition_source = create(:acquisition_source)
          token = EmailTrackingToken.encode_with_source(acquisition_source.id)

          page = create(:page_with_parent)
          petition = create(:petition_module)
          create(:content_module_link, :content_module => petition, :page => page, :layout_container => :sidebar)

          params = {
            :module_id => petition.id,
            :user => {:email => new_email},
            :campaign_id => page.page_sequence.campaign.friendly_id,
            :page_sequence_id => page.page_sequence.friendly_id,
            :id => page.id,
            :t => token,
            petition_signature: {}
          }
          post :take_action, params

          new_user = User.find_by_email(new_email)
          expect(new_user.user_activity_events.subscriptions.last.acquisition_source).to eq(acquisition_source)
        end
      end
    end
  end

  describe "email tracking token is present" do
    without_transactional_fixtures do
      it "should create a shared connection" do
        with_push_table do
          token_user = create(:user, email: 'test1@email.com')
          user = create(:user, email: 'test2@email.com')
          email = create(:email)
          token = EmailTrackingToken.encode(token_user.id, email.id)

          page = create(:page_with_parent)
          petition = create(:petition_module)
          create(:content_module_link, :content_module => petition, :page => page, :layout_container => :sidebar)

          params = {
            :module_id => petition.id,
            :user => {:email => user.email},
            :campaign_id => page.page_sequence.campaign.friendly_id,
            :page_sequence_id => page.page_sequence.friendly_id,
            :id => page.id,
            :t => token,
            petition_signature: {}
          }
          post :take_action, params

          shared_connection = SharedConnections.first
          shared_connection.originator.should == token_user
          shared_connection.action_taker.should == user

          uae = UserActivityEvent.find_last_by_user_id(user.id)
          shared_connection.user_activity_event.should == uae
        end
      end
    end
  end

  describe "email tracking token is not present" do
    without_transactional_fixtures do
      it "should not create a shared connection" do
        with_push_table do
          user = create(:user, email: 'test2@email.com')
          email = create(:email)

          page = create(:page_with_parent)
          petition = create(:petition_module)
          create(:content_module_link, :content_module => petition, :page => page, :layout_container => :sidebar)

          params = {
            :module_id => petition.id,
            :user => {:email => user.email},
            :campaign_id => page.page_sequence.campaign.friendly_id,
            :page_sequence_id => page.page_sequence.friendly_id,
            :id => page.id,
            petition_signature: {}
          }
          post :take_action, params

          SharedConnections.first.should be_nil
        end
      end
    end
  end

  describe "finding the email" do
    without_transactional_fixtures do
      before(:each) do
        @page = create(:page_with_parent, :required_user_details => {:first_name => :required})
        @user = create(:user, :email => 'BRUCE@example.com')
        @email = create(:email)
      end

      it "identifies the appropriate referring email" do
        petition = create(:petition_module)
        ContentModuleLink.create!(:content_module => petition, :page => @page, :layout_container => :sidebar)

        params = {
          :module_id => petition.id,
          :user => {:email => "bruce@example.com"},
          :campaign_id => @page.page_sequence.campaign.friendly_id,
          :page_sequence_id => @page.page_sequence.friendly_id,
          :id => @page.friendly_id,
          :t => EmailTrackingToken.encode(@user.id, @email.id),
          petition_signature: {}
        }
        post :take_action, params
        assigns(:email).id.should == @email.id
      end
    end
  end

  describe "#identify_ask" do
    context 'with valid ask module' do
      it "identifies ask module in memory, ensures same instance and sets pass through properties" do
        current_user = create(:user)
        sign_in current_user
        page = create(:page_with_parent, :required_user_details => {:first_name => :required})
        ask = create(:petition_module)
        another_ask = create(:petition_module)
        ContentModuleLink.create!(:page => page, :content_module => ask, :layout_container => :sidebar)
        ContentModuleLink.create!(:page => page, :content_module => another_ask, :layout_container => :sidebar)

        params = {
          :module_id => ask.id,
          :user => {:first_name => "Bruce",
                    :email => "bruce@example.com"},
          :campaign_id => page.page_sequence.campaign.friendly_id,
          :page_sequence_id => page.page_sequence.friendly_id,
          :id => page.id,
          petition_signature: {}
        }
        post :take_action, params

        ask_from_page = assigns(:page).sidebar_content_modules.first

        assigns(:ask).object_id.should == ask_from_page.object_id
        assigns(:ask).user_notifier.should_not be_nil
        assigns(:ask).email_notifier.should_not be_nil
        assigns(:ask).session.should == session
        assigns(:ask).cookies.should == cookies
        assigns(:ask).current_user.should == current_user
      end
    end

    context 'with invalid ask module' do
      it "should redirect to the homepage if the ask does not match the page" do
        ask = create(:petition_module)
        take_action(ask.id)
        assigns(:ask).should be_nil
      end

      it "should redirect to the homepage if the ask does not exist" do
        take_action(-1)
      end
    end
  end

  describe "page on success" do
    before do
      @user = create(:user)
      @p1 = create(:page_with_parent, :position => 1, :thankyou_email_text => 'Lorem ipsum', :thankyou_email_subject => 'Subjective subject')
      @seq = @p1.page_sequence

      @p1_ask = create(:petition_module)
      ContentModuleLink.create!(:page => @p1, :content_module => @p1_ask, :layout_container => :main_content)

      @p2 = Page.create!(:page_sequence => @seq, :position => 2, :name => "Second Page")
      @p2_ask = create(:petition_module)
      ContentModuleLink.create!(:page => @p2, :content_module => @p2_ask, :layout_container => :main_content)

      ActionMailer::Base.deliveries = []
    end

    it "advances to next page on success" do
      post :take_action, {:module_id => @p1_ask.id, :user => {:email => @user.email}, :campaign_id => @p1.page_sequence.campaign.friendly_id, :page_sequence_id => @p1.page_sequence.friendly_id, :id => @p1.id, petition_signature: {}}
      response.should redirect_to(page_path(@seq.campaign.friendly_id, @seq.friendly_id, @p2.friendly_id))
    end

    it 'should call take_action on module' do
      PetitionModule.any_instance.should_receive :take_action
      post :take_action, {:module_id => @p1_ask.id, :user => {:email => @user.email}, :campaign_id => @p1.page_sequence.campaign.friendly_id, :page_sequence_id => @p1.page_sequence.friendly_id, :id => @p1.id, petition_signature: {}}
    end

    context "last_page_url defined" do

      before :each do
        @p2.page_sequence.last_page_url = "http://last.page.url/"
        @p2.page_sequence.save
      end

      it "redirects to last page url if no next page" do
        post :take_action, {
          :module_id => @p2_ask.id,
          :user => {
            :email => @user.email
          },
          :campaign_id => @p2.page_sequence.campaign.friendly_id,
          :page_sequence_id => @p2.page_sequence.friendly_id,
          :id => @p2.id,
          petition_signature: {}
        }
        response.redirect_url.should =~ /last.page.url/
      end

      it "redirects to next page if next page present" do
        post :take_action, {
          :module_id => @p1_ask.id,
          :user => {
            :email => @user.email
          },
          :campaign_id => @p1.page_sequence.campaign.friendly_id,
          :page_sequence_id => @p1.page_sequence.friendly_id,
          :id => @p1.id,
          petition_signature: {}
        }
        response.should redirect_to(page_path(@seq.campaign.friendly_id, @seq.friendly_id, @p2.friendly_id))
      end
    end

    it "should redirect to root path if no next page, and no last_page_url" do
      post :take_action, {
        :module_id => @p2_ask.id,
        :user => {
          :email => @user.email
        },
        :campaign_id => @p2.page_sequence.campaign.friendly_id,
        :page_sequence_id => @p2.page_sequence.friendly_id,
        :id => @p2.id,
        petition_signature: {}
      }
      response.should redirect_to(root_path)
    end

    it "uses the correct URL for the next static page" do
      @p1.page_sequence.update_attributes!(:campaign => nil)
      post :take_action, {:module_id => @p1_ask.id, :user => {:email => @user.email}, :campaign_id => nil, :page_sequence_id => @p1.page_sequence.friendly_id, :id => @p1.id, petition_signature: {}}
      response.should redirect_to(page_path(nil, @seq.friendly_id, @p2.friendly_id))
    end

    it "renders the same page on failure" do
      @p1.update_attributes!(:required_user_details => {:first_name => :required})
      post :take_action, {:module_id => @p1_ask.id, :user => {:email => "henry@ford.com"}, :campaign_id => @p1.page_sequence.campaign.friendly_id, :page_sequence_id => @p1.page_sequence.friendly_id, :id => @p1.id, petition_signature: {}}
      response.should render_template("pages/show")
    end

    it "renders the same page when no email passed in" do
      post :take_action, {:module_id => @p1_ask.id, :campaign_id => @p1.page_sequence.campaign.friendly_id, :page_sequence_id => @p1.page_sequence.friendly_id, :id => @p1.id}
      response.should redirect_to(page_path(@p1.page_sequence.campaign.friendly_id, @seq.friendly_id, @p1.friendly_id))
    end

    describe "sending thankyou email" do
      it "queues an email if appropriate" do
        @p1.update_attributes!(:send_thankyou_email => true, :thankyou_email_subject => "Thanks!", :thankyou_email_text => "You're great.")
        post :take_action, {:module_id => @p1_ask.id, :user => {:email => @user.email}, :campaign_id => @p1.page_sequence.campaign.friendly_id, :page_sequence_id => @p1.page_sequence.friendly_id, :id => @p1.id, petition_signature: {}}
        response.should redirect_to(page_path(@seq.campaign.friendly_id, @seq.friendly_id, @p2.friendly_id))

        ActionMailer::Base.should have(1).deliveries
        @email = ActionMailer::Base.deliveries.last
        @email.should deliver_to(@user.email)
        @email.should have_subject(/Thanks!/)
        @email.should have_body_text(/You're great./)
      end

      it "does not queue and email is not appropriate" do
        @p1.update_attributes!(:send_thankyou_email => false)
        post :take_action, {:module_id => @p1_ask.id, :user => {:email => @user.email}, :campaign_id => @p1.page_sequence.campaign.friendly_id, :page_sequence_id => @p1.page_sequence.friendly_id, :id => @p1.id, petition_signature: {}}
        response.should redirect_to(page_path(@seq.campaign.friendly_id, @seq.friendly_id, @p2.friendly_id))

        ActionMailer::Base.deliveries.should be_empty
      end
    end

    describe "duplicate actions taken" do
      it "progresses to the next page but does not send email or save duplicate action" do
        Vanity.stub(:ab_test).and_return(:control)
        @p1_ask.take_action(@user, @p1).save!
        PetitionSignature.count.should == 1

        post :take_action, {:module_id => @p1_ask.id, :user => {:email => @user.email}, :campaign_id => @p1.page_sequence.campaign.friendly_id, :page_sequence_id => @p1.page_sequence.friendly_id, :id => @p1.id, petition_signature: {}}
        response.should redirect_to(page_path(@seq.campaign.friendly_id, @seq.friendly_id, @p2.friendly_id))
        PetitionSignature.count.should == 1
        ActionMailer::Base.deliveries.should be_empty
      end
    end
  end

  describe "non-creditcard payments" do
    before(:each) do
      @ask = create(:donation_module)
      @donate_page = create(:page_with_parent, :name => "Donate Page")
      @thanks_page = create(:page_with_parent, :page_sequence => @donate_page.page_sequence, :name => "Thanks Page")
      ContentModuleLink.create!(:page => @thanks_page, :content_module => create(:html_module))
      ContentModuleLink.create!(:page => @donate_page, :content_module => @ask, layout_container: :main_content)
    end

    describe "paypal return posts" do
      it "redirects to next page on success" do
        post :paypal_completed, :campaign_id => @donate_page.page_sequence.campaign.friendly_id, :page_sequence_id => @donate_page.page_sequence.friendly_id, :id => @donate_page.id
        response.should redirect_to(page_path(@thanks_page.page_sequence.campaign.friendly_id, @thanks_page.page_sequence.friendly_id, @thanks_page.friendly_id))
      end
      it "redirects to own page on cancel" do
        get :paypal_cancel, :campaign_id => @donate_page.page_sequence.campaign.friendly_id, :page_sequence_id => @donate_page.page_sequence.friendly_id, :id => @donate_page.id
        response.should redirect_to(page_path(@donate_page.page_sequence.campaign.friendly_id, @donate_page.page_sequence.friendly_id, @donate_page.friendly_id))
      end
    end

    describe "non-javascript" do
      it "renders instructions for non-js cheque donations" do
        get :cheque, :campaign_id => @donate_page.page_sequence.campaign.friendly_id, :page_sequence_id => @donate_page.page_sequence.friendly_id, :id => @donate_page.id
        response.should be_success
      end
      it "renders instructions for non-js paypal donations" do
        get :paypal, :campaign_id => @donate_page.page_sequence.campaign.friendly_id, :page_sequence_id => @donate_page.page_sequence.friendly_id, :id => @donate_page.id
        response.should be_success
      end
      it "gives bad request if no DonationModule on page" do
        get :paypal, :campaign_id => @donate_page.page_sequence.campaign.friendly_id, :page_sequence_id => @donate_page.page_sequence.friendly_id, :id => @thanks_page.id
        response.status.should == 400
      end
    end
  end

  describe "pagination" do
    before(:each) do
      @page = create(:page_with_parent)
      @page.content_module_links.create!(:layout_container => :main_content, :content_module => create(:past_campaign_module))
      @page.content_module_links.create!(:layout_container => :main_content, :content_module => create(:past_campaign_module))
      @page.content_module_links.create!(:layout_container => :main_content, :content_module => create(:past_campaign_module))
      @page.content_module_links.create!(:layout_container => :main_content, :content_module => create(:past_campaign_module))
      @page.content_module_links.create!(:layout_container => :main_content, :content_module => create(:past_campaign_module))
      @page.content_module_links.create!(:layout_container => :main_content, :content_module => create(:past_campaign_module))
      @params = {
        :campaign_id => @page.page_sequence.campaign.friendly_id,
        :page_sequence_id => @page.page_sequence.friendly_id,
        :id => @page.friendly_id
      }
    end


    it "paginates main content modules for pages that have this option set" do
      @page.update_attribute(:paginate_main_content, true)

      get :show, @params

      assigns(:valid_main_content_modules).size.should eql 5
      assigns(:valid_main_content_modules).total_pages.should eql 2
      assigns(:valid_main_content_modules).current_page.should eql 1
    end

    it "doesn't paginate main content modules for pages that don't have this option set" do
      get :show, @params
      assigns(:valid_main_content_modules).size.should eql 6
    end

    it "can handle invalid page requests" do
      @page.update_attribute(:paginate_main_content, true)
      get :show, @params.merge({page: 'asdf'})
      assigns(:valid_main_content_modules).current_page.should eql 1

      get :show, @params.merge({page: '2gaweoigio-90289*(!#(*$^\'; drop table users; --'})
    end
  end

  describe "#show" do
    before(:each) do
      @page = create(:page_with_parent)
      @page.content_module_links.create!(:layout_container => :main_content, :content_module => create(:html_module))
      @page.content_module_links.create!(:layout_container => :sidebar, :content_module => create(:donation_module))
      @params = {
        :campaign_id => @page.page_sequence.campaign.friendly_id,
        :page_sequence_id => @page.page_sequence.friendly_id,
        :id => @page.friendly_id
      }
    end

    it "sets module properties to make them first class controller like objects" do
      get :show, @params
      modules = assigns(:page).all_content_modules
      modules.length.should == 2
      modules.each do |cm|
        cm.cookies.should == cookies
        cm.session.should == session
        cm.params.should include @params
        cm.user_notifier.should be
        cm.email_notifier.should be
      end
    end
  end

  describe "return" do
    it "should write the return value to the session" do
      @page = create(:page_with_parent, :name => "Original Name")
      @ps = @page.page_sequence.friendly_id
      @cam = @page.page_sequence.campaign.friendly_id
      @page.name = "New Name"
      @page.save!
      session[:return_to] = nil
      get :show, :campaign_id => @cam, :page_sequence_id => @ps, :id => "original-name", :return_to => "/events/23"
      session[:return_to].should == "/events/23"
    end
  end

  describe "error handling" do
    it "should return a record not found error for unknown ids" do
      post :take_action, page_sequence_id: 99999, id: 999999
      expect(response.code).to eq("404")
    end
  end

  def take_action(ask_id)
    page = create(:page_with_parent, :required_user_details => {:first_name => :required})

    params = {
      :module_id => ask_id,
      :user => {:first_name => "Bruce",
                :email => "bruce@example.com"},
      :campaign_id => page.page_sequence.campaign.friendly_id,
      :page_sequence_id => page.page_sequence.friendly_id,
      :id => page.id
    }
    post :take_action, params
    response.should redirect_to(root_path)
  end

  describe "page theme" do
    it "should override campaign theme with page sequence theme" do
      campaign = create(:campaign, theme: create(:theme))
      page_sequence = create(:page_sequence, campaign: campaign, theme: create(:theme_happy))
      page = create(:page, page_sequence: page_sequence, :required_user_details => {:first_name => :required})

      params = {
        :campaign_id => page.page_sequence.campaign.friendly_id,
        :page_sequence_id => page.page_sequence.friendly_id,
        :id => page.friendly_id
      }

      get :show, params

      response.should render_template(:layout => 'layouts/themes/happy')
    end

    it "should use campaign theme when page sequence theme is not set" do
      campaign = create(:campaign, theme: create(:theme_happy))
      page_sequence = create(:page_sequence, campaign: campaign, theme: nil)
      page = create(:page, page_sequence: page_sequence, :required_user_details => {:first_name => :required})

      params = {
        :campaign_id => page.page_sequence.campaign.friendly_id,
        :page_sequence_id => page.page_sequence.friendly_id,
        :id => page.friendly_id
      }

      get :show, params

      response.should render_template(:layout => 'layouts/themes/happy')
    end
  end

  describe "#identify_campaign" do
    context "request comes from default domain" do
      context "with campaign_name" do
        it "should retrieve a valid campaign" do
          campaign = create(:campaign)
          controller.send(:identify_campaign, campaign.friendly_id).should == campaign
        end

        context "without campaign_name" do
          it "should return nil" do
            controller.send(:identify_campaign).should == nil
          end
        end
      end
    end

    context "request comes from cloaked domain" do
      it "should retrieve a campaign" do
        campaign = create(:campaign, :name => "community-run-content")
        controller.request.stub(:host).and_return("content.communityrun.org")
        controller.send(:identify_campaign).should == campaign
      end
    end
  end

  describe "#take_action" do
    context "quick donate cookie" do
      let!(:quick_donate_user){ create(:user, first_name: 'James', last_name: 'Test', :quick_donate_trigger_id => 'abc') }
      let!(:donation) { create(:donation, :trigger_id => 'abc') }
      let!(:page){ create(:page_with_parent, :required_user_details => {:first_name => :required}) }
      let!(:content_module){ create(:donation_module) }
      let!(:module_link){ ContentModuleLink.create!(:page => page, :content_module => content_module, :layout_container => :main_content) }
      let!(:post_params){
        {
          module_id: content_module.id,
          user: { email: quick_donate_user.email},
          campaign_id: page.page_sequence.campaign.friendly_id,
          page_sequence_id: page.page_sequence.friendly_id,
          id: page.id,
          donation: { payment_method: 'credit_card' }
        }
      }

      context "stored user details (quick donate)" do
        let!(:content_module){ create(:donation_module) }
        let!(:post_params){
          {
            module_id: content_module.id,
            campaign_id: page.page_sequence.campaign.friendly_id,
            page_sequence_id: page.page_sequence.friendly_id,
            id: page.id,
            donation: { payment_method: 'credit_card' }
          }
        }

        it 'should use stored user and not fail validation' do
          cookies.permanent.signed[:quick_donate_user_id] = quick_donate_user.id
          DonationModule.any_instance.should_receive(:take_action)
          post :take_action, post_params
          assigns(:user).should == quick_donate_user
        end
      end
    end

    context "when using vanity for A/B testing and a donation is made" do
      let!(:user){ create(:user, first_name: 'James', last_name: 'Test') }
      let!(:page){ create(:page_with_parent, :required_user_details => {:first_name => :required}) }
      let!(:content_module){ create(:donation_module) }
      let!(:module_link){ ContentModuleLink.create!(:page => page, :content_module => content_module, :layout_container => :main_content) }
      let!(:amount_donated){ 30.75 }
      let!(:amount_donated_in_cents){ (amount_donated * 100).to_i }
      let!(:post_params){
        {
          module_id: content_module.id,
          user: { email: user.email},
          campaign_id: page.page_sequence.campaign.friendly_id,
          page_sequence_id: page.page_sequence.friendly_id,
          id: page.id,
          donation: { payment_method: 'credit_card', amount_in_dollars: amount_donated, name_on_card: 'test', card_number: '1', card_cvv: '111', card_expiry_month: '01', card_expiry_year: Time.current.year + 1 }
        }
      }
      before{ Setting.stub(:[]).with(:use_cc_logging).and_return('true') }
      before{ Setting.stub(:[]).with(:use_fraud_guard).and_return('false') }
      before{ Setting.stub(:[]).with(:auto_daisy_chains).and_return(nil) }
      before{ Setting.stub(:[]).with('gateway1_percentage').and_return(100) }

      context "a donation is made" do
        it 'should track the donation amount recorded' do
          controller.should_receive(:track_with_user).once.ordered.with(:money, amount_donated_in_cents, user, kind_of(Donation))
          controller.should_receive(:track_with_user).once.ordered #receives 2 calls, the 2nd call with different arguments
          post :take_action, post_params
        end
      end

      it "should record conversions in vanity" do
        controller.should_receive(:track_with_user).once.ordered #receives 2 calls, the 2nd call for recording actions
        controller.should_receive(:track_with_user).once.ordered.with(:actions, 1, user, nil)
        post :take_action, post_params
      end
    end

    context "after a successful action" do
      let!(:page){ create(:page_with_parent) }
      let!(:ask){ create(:petition_module) }
      # ensure petition isn't the only module on the page
      let!(:html_link){ ContentModuleLink.create!(page: page, content_module: create(:html_module), :layout_container => :main_content) }
      let!(:link){ ContentModuleLink.create!(page: page, content_module: ask, :layout_container => :sidebar) }
      let(:params){ {
        module_id: ask.id,
        user: { email: 'test@test.com' },
        campaign_id: page.page_sequence.campaign.friendly_id,
        page_sequence_id: page.page_sequence.friendly_id,
        t: 'xxxx',
        id: page.id,
        petition_signature: {}
      } }
      let(:user_that_took_action){ User.find_by_email(params[:user][:email]) }

      it "should set a secure cookie with the users's id" do
        post :take_action, params
        expect(cookies.permanent.signed[:user_id]).to eql(user_that_took_action.id)
      end

      context "with a daisy chain page available for the pillar" do
        before{ Setting[:auto_daisy_chains] = '1' }
        let!(:campaign_in_same_pillar){ create(:campaign, accounts_key: page.page_sequence.campaign.accounts_key) }
        let!(:daisy_page_sequence){ create(:page_sequence, campaign: campaign_in_same_pillar, name: "#{AppConstants.daisy_chain_prefix} test") }
        let!(:daisy_page){ create(:page, page_sequence: daisy_page_sequence) }

        context "with a page with a 'daisy' tag" do
          before { page.tag_list = 'daisy'; page.save! }
          let!(:thank_you_page){ create(:page, page_sequence: page.page_sequence, name: 'thank you') }

          context "with a user in the control group" do
            before { Vanity.stub(:ab_test).and_return(:control) }
            it "shows the user the standard 'thank you' page" do
              post :take_action, params
              response.should redirect_to(friendly_path(thank_you_page, t: params[:t], exp: 'ctrl'))
            end
          end

          context "with a user in the treatment group" do
            before { Vanity.stub(:ab_test).and_return(:treatment) }
            it "shows the user the automated daisy chain" do
              post :take_action, params
              response.should redirect_to(friendly_path(daisy_page, t: params[:t], via: params[:id], exp: 'tmnt'))
            end
          end
        end

        context "with the same module type as the previous page" do
          render_views
          before do
            ContentModuleLink.create!(page: daisy_page, content_module: create(:petition_module), :layout_container => :sidebar)
            ContentModuleLink.create!(page: daisy_page, content_module: create(:tell_a_friend_module), :layout_container => :sidebar)
          end
          let(:params){ {
            campaign_id: campaign_in_same_pillar.friendly_id,
            page_sequence_id: daisy_page_sequence.friendly_id,
            id: daisy_page.friendly_id,
            via: page.id
          } }

          it "should be excluded" do
            get :show, params
            response.body.should_not =~ /<div class='petition-content'>/
            response.body.should =~ /<div class='content-module tell-a-friend-module main-content'>/
          end
        end
      end
    end
  end

  describe "#identify_page_sequence" do
    it "should retrieve a valid page_sequence" do
      campaign = create(:campaign)
      page_sequence = create(:page_sequence, :campaign => campaign)
      controller.send(:identify_page_sequence, campaign, page_sequence.id).should == page_sequence
    end
  end

  describe "#friendly_path" do
    it "should return page_path if request comes from default domain" do
      campaign = create(:campaign)
      page_sequence = create(:page_sequence, :campaign => campaign)
      page = create(:page, :page_sequence => page_sequence)
      controller.send(:friendly_path, page).should == page_path(campaign.friendly_id, page_sequence.friendly_id, page.friendly_id)
    end

    it "should return cloaked_path if request comes from cloaked host" do
      campaign = create(:campaign, :name => "community-run-content")
      page_sequence = create(:page_sequence, :campaign => campaign)
      page = create(:page, :page_sequence => page_sequence)
      controller.request.stub(:host).and_return("content.communityrun.org")
      controller.send(:friendly_path, page).should == cloaked_path(page_sequence.friendly_id, page.friendly_id)
    end
  end

  context "with a user that has a secure cookie" do
    render_views
    let(:page){ create(:page_with_parent, :user_details_default, name: 'showcase') }
    let(:petition){ create(:petition_module) }
    let!(:content_module_link){ create(:content_module_link, page: page, content_module: petition) }
    let(:secure_user){ create(:user_with_details, first_name: 'Malala', last_name: 'Yousafzai') }
    let(:page_path){
      {
        campaign_id: page.page_sequence.campaign.friendly_id,
        page_sequence_id: page.page_sequence.friendly_id,
        id: page.friendly_id
      }
    }
    before do
      cookies.permanent.signed[:user_id] = secure_user.id
    end

    describe "#show with an action" do
      context "with no 'required' or 'refresh' fields" do
        it "should show the one-click sign form" do
          get :show, page_path
          expect(response.body).to include(secure_user.name)
          expect(response.body).to include('use_cookie')
        end
      end

      context "with required fields or refresh fields" do
        let!(:page){ create(:page_with_parent, :user_details_required) }
        it "should NOT show the one-click sign form" do
          get :show, page_path
          expect(response.body).not_to include(secure_user.name)
          expect(response.body).not_to include('use_cookie')
        end
      end

      context "with the page with tag 'disable-one-click'" do
        let!(:page){ create(:page_with_parent, :user_details_default, name: 'showcase', tag_list: 'disable-one-click') }
        it "should NOT show the one-click sign form" do
          get :show, page_path
          expect(response.body).not_to include('use_cookie')
        end
      end
    end

    describe "#take_action with use_cookie parameter" do
      let!(:params) {
        {
          module_id: petition.id,
          use_cookie: 1,
          campaign_id: page.page_sequence.campaign.friendly_id,
          page_sequence_id: page.page_sequence.friendly_id,
          id: page.id,
          petition_signature: {}
        }
      }
      it "should use the user details from the secure cookie" do
        post :take_action, params
        expect(response).to be_redirect
        secure_user.reload
        expect(secure_user.user_activity_events.actions_taken.length).to eq(1)
      end
    end

    describe "#take_action with a secure user but no use_cookie parameter" do
      let!(:params) {
        {
          module_id: petition.id,
          user: {email: "bruce@example.com", is_member: '1', first_name: 'Bruce', last_name: 'Yo', postcode_number: '2000'},
          campaign_id: page.page_sequence.campaign.friendly_id,
          page_sequence_id: page.page_sequence.friendly_id,
          id: page.id,
          petition_signature: {}
        }
      }
      it "should ignore the cookie" do
        post :take_action, params
        expect(response).to be_redirect
        secure_user.reload
        expect(secure_user.user_activity_events.actions_taken.length).to eq(0)
        new_user = User.find_by_email('bruce@example.com')
        expect(new_user.user_activity_events.actions_taken.length).to eq(1)
        expect(response.cookies["user_track"].to_i).to eq(new_user.id)
      end
    end
  end

  context "with a user that has an email token" do
    render_views
    let(:user) { create(:user, first_name: 'Malala', last_name: 'Yousafzai') }
    let(:token) { EmailTrackingToken.encode(user.id, 1) }
    let(:petition) { create(:petition_module) }
    let(:page) { create(:page_with_parent, tag_list: 'token-recognition') }
    let!(:cml) { create(:content_module_link, page: page, content_module: petition) }
    let(:page_params) {
      {
        campaign_id: page.page_sequence.campaign.friendly_id,
        page_sequence_id: page.page_sequence.friendly_id,
        id: page.friendly_id,
        t: token
      }
    }
    describe "#show with an action" do
      context "with no 'required' or 'refresh' fields" do
        it "sets the 'user_id' cookie" do
          get :show, page_params
          expect(cookies.permanent.signed[:user_id]).to eql(user.id)
        end

        it "shows the one-click sign form" do
          get :show, page_params
          expect(response.body).to include(user.name)
        end
      end

      context "with required fields or refresh fields" do
        let!(:page){ create(:page_with_parent, :user_details_required) }
        it "does NOT show the one-click sign form" do
          get :show, page_params
          expect(response.body).not_to include(user.name)
        end
      end

      context "without the 'token-recognition' page tag" do
        let!(:page) { create(:page_with_parent) }
        it "does NOT show the one-click sign form" do
          get :show, page_params
          expect(response.body).not_to include(user.name)
        end
      end
    end

    describe "#take_action" do
      let(:params) {
        {
          module_id: petition.id,
          campaign_id: page.page_sequence.campaign.friendly_id,
          page_sequence_id: page.page_sequence.friendly_id,
          id: page.friendly_id,
          petition_signature: {},
          use_cookie: 1,
        }
      }
      before { cookies.permanent.signed[:user_id] = user.id }

      it "uses the cookie" do
        post :take_action, params
        expect(response).to be_redirect
        user.reload
        expect(user.user_activity_events.actions_taken.length).to eq(1)
      end
    end
  end
end
