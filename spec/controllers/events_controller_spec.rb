require File.expand_path(File.dirname(__FILE__) + "../../spec_helper")

describe EventsController do
  include Devise::TestHelpers

  before :each do
    sign_in @user = create(:user, :is_admin => false)
    @event = create(:event)
  end

  describe "#edit" do
    it "should allow the logged in host to edit the event" do
      Event.stub(:find).and_return(@event)
      @event.stub(:host).and_return @user
      response = get :edit, :id => @event.id
      response.status.should == 200
    end
  
    it "should disallow the logged in host to edit an admin-managed event" do
      admin_managed_event = create(:admin_managed_event)
      Event.stub(:find).and_return(admin_managed_event)
      admin_managed_event.stub(:host).and_return @user
      response = get :edit, :id => admin_managed_event.id
      response.status.should == 401
    end

    it "should allow an admin to edit an admin-managed event" do
      @user.is_admin = true
      @user.save
      admin_managed_event = create(:admin_managed_event)
      Event.stub(:find).and_return(admin_managed_event)
      admin_managed_event.stub(:host).and_return @user
      response = get :edit, :id => admin_managed_event.id
      response.status.should == 200
    end

    it "redirects to the login page if there is nobody logged in" do
      controller.stub(:current_user) { nil }
      Event.should_receive(:find).with(@event[:id].to_s).and_return(@event)
      response = get :edit, :id => @event.id
      response.status.should == 302
    end

    it "returns a 401 and custom failure if the currently logged in user is not the host" do
      Event.should_receive(:find).with(@event[:id].to_s).and_return(@event)
      
      @event.should_receive(:host).and_return create(:user)

      response = get :edit, :id => @event.id
      response.status.should == 401
    end

    it "should return a record not found error for unknown ids" do
      expect { get :edit, :id => "i-am-a-random-id-here" }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe "#update" do
    context "editing host" do
      before :each do
        Event.stub(:find).and_return(@event)
      end
      it "should redirect to sign in page when not logged in" do
        sign_out @user
        response = put :update, :id => @event.id, host: { email: "other@host.com"}
        response.should redirect_to new_user_session_path
      end

      it "should allow an admin to edit the host of an event" do
        @user.update_attribute(:is_admin, true)
        response = put :update, :id => @event.id, host: { email: "other@host.com"}
        response.should redirect_to event_path(@event)
        @event.host.email.should == "other@host.com"
      end

      it "should create a UserActivityEvent for new host" do
        new_host = create(:user, email: "other@host.com")
        @user.update_attribute(:is_admin, true)
        UserActivityEvent.should_receive(:registered_to_host!).with(new_host, @event)
        put :update, :id => @event.id, host: { email: "other@host.com"}
      end

      it "should NOT create a UserActivityEvent is host is unchanged" do
        @user.update_attribute(:is_admin, true)
        UserActivityEvent.should_not_receive(:registered_to_host!)
        put :update, :id => @event.id, host: { email: @event.host.email}
      end

      it "should disallow the logged in host to edit the host of an event" do
        @event.stub(:host).and_return @user
        response = put :update, :id => @event.id, host: { email: "other@host.com"}
        response.should redirect_to event_path(@event)
        @event.host.email.should == @user.email
      end
    end
  end

  describe "#new" do
    it "should create a new event" do
      get_together = create(:get_together, :from_date => Time.now+2.days, :to_date => Time.now+4.days)
      get :new, :get_together_id => get_together.id
      assigns(:event).should be_a_new_record
      assigns(:event).should_not be_nil
      assigns(:event).get_together.should == get_together
      response.status.should == 200
    end

    it "should not create an event if there is no Get Together assigned" do
      get :new
      assigns(:event).should be_nil
      response.should redirect_to(get_togethers_path)
    end

  end

  describe "POST create" do
    before :each do
      @postcode = create(:postcode)
      @get_together = create(:get_together, :from_date => Date.today, :to_date => Date.tomorrow, :from_time => 1600, :to_time => 1800, :is_admin_managed => true)
      @event_details =  {
        :name => "My event",
        :date => Date.today,
        :time => 1700,
        :address => "Level 8, 51 Pitt Street Sydney NSW 2000",
        :phone => "2222222",
        :capacity => 45,
        :host_notes => "I'm hosting this awesome event. Come along!",
        :host_id => create(:user).id,
        :terms_and_conditions => true,
        :address_latitude => @postcode.latitude,
        :address_longitude => @postcode.longitude
      }
    end

    it "should create an event and redirect to the show page" do
      user = create(:user, :email => "herd.mcgerkinshaw@getup.org.au")
      post :create, :id => @event.id, :event => @event_details, :get_together_id => @get_together.id, :host => {:email => "herd.mcgerkinshaw@getup.org.au"}
      event = assigns(:event)
      event.should_not be_new_record
      event.confirmed?.should == false
      response.should redirect_to(event_path(event.friendly_id))
    end

    it 'should register a UserActivityEvent record with an email id when a token is present' do
      user = create(:user, :email => "herd.mcgerkinshaw@getup.org.au")
      email = create(:email)
      t = EmailTrackingToken.encode user.id, email.id
      post :create, :id => @event.id, :event => @event_details, :get_together_id => @get_together.id, :host => {:email => "herd.mcgerkinshaw@getup.org.au"}, :t => t
      uae = UserActivityEvent.find_last_by_email_id(email.id)
      uae.email.should == email
      uae.user.should == user
    end

    it "should not save an event if the user email is invalid" do
      post :create, :id => @event.id, :event => @event_details, :get_together_id => @get_together.id, :host => {:email => "herd.mcgerkinshaw@x"}
      event = assigns(:event)
      event.host.should be_new_record
      event.new_record?.should be true
      flash[:error].should == "Your event has not been saved. Please fix the errors below."
      response.should render_template('new')
    end

    it "should assign the user with email address" do
      user = create(:user, :email => "herd.mcgerkinshaw@getup.org.au")
      post :create, :id => @event.id, :event => @event_details, :get_together_id => @get_together.id, :host => {:email => "herd.mcgerkinshaw@getup.org.au"}
      event = assigns(:event)
      event.host.should == user
    end

    it "should create a user with email address if there isn't one and he's not logged in" do
      controller.stub(:current_user) { nil } # not logged in
      post :create, :id => @event.id, :event => @event_details, :get_together_id => @get_together.id, :host => {:email => "user.not.already.in.system@getup.org.au"}
      event = assigns(:event)
      user = event.host
      user.email.should == "user.not.already.in.system@getup.org.au"
    end

    it "raise error and does not create new event if it is within the exclusion zone of the related managed get together" do
      community_get_together = create(:get_together, :managed_get_together => @get_together, :from_date => Date.today, :to_date => Date.tomorrow, :from_time => 1600, :to_time => 1800)
      @get_together.events.create(@event_details.merge(:confirmed_at => Date.today))
      expect {
        post :create, :event => @event_details, :get_together_id => community_get_together.id, :host => {:email => "herd.mcgerkinshaw@getup.org.au"}
      }.to raise_error(RuntimeError, /not create event within exclusion radius/)
      community_get_together.events.should be_empty
    end

    context "current user is not an admin" do
      let(:host_user) { create(:user, :is_admin => false) }

      it "should not be confirmed immediately" do
        post :create, :event => @event_details, :get_together_id => @get_together.id, :host => {:email => host_user.email}
        event = assigns(:event)
        event.confirmed?.should == false
      end

      it "should not create a host activity event" do
        UserActivityEvent.should_not_receive(:registered_to_host!)
        post :create, :event => @event_details, :get_together_id => @get_together.id, :host => {:email => host_user.email}
      end
    end

    context "current user is an admin" do
      before :each do
        sign_in @user = create(:user, :is_admin => true)
        @host_user = create(:user, :is_admin => false)
      end

      it "should be confirmed immediately" do
        post :create, :event => @event_details, :get_together_id => @get_together.id, :host => {:email => @host_user.email}
        event = assigns(:event)
        event.confirmed?.should == true
      end

      it "should create a host activity event" do
        UserActivityEvent.should_receive(:registered_to_host!)
        post :create, :event => @event_details, :get_together_id => @get_together.id, :host => {:email => @host_user.email}
      end
    end
  end

  describe "GET confirm" do
    it "should redirect to the event's public view if a valid confirmation code has been provided" do
      get :confirm, :cd => @event.confirmation_code

      response.should redirect_to(event_path(@event.friendly_id))
      flash[:notice].should == "Your event has been confirmed!"
    end

    it "should create a registered to host activity event" do
      UserActivityEvent.should_receive(:registered_to_host!).with(@event.host, @event)
      get :confirm, :cd => @event.confirmation_code
    end

    it "should redirect to the main page if a matching event could not be found" do
      get :confirm, :cd => "invalid"
      response.should redirect_to(root_path)
    end
  end

  describe "POST cancel" do
    it "should cancel the event given the logged_in user is the host" do
      event = create(:event, :host => @user)
      post :cancel, :id => event

      response.should redirect_to(event_path(event.friendly_id))
      flash[:notice].should == "Your event has been canceled!"
    end

    it "should cancel the event given the logged_in user is an admin user" do
      event = create(:event, :host => create(:user))
      @user.update_attributes(:is_admin => true)

      post :cancel, :id => event
      response.should redirect_to(event_path(event.friendly_id))
      flash[:notice].should == "Your event has been canceled!"
    end

    it "should respond with Unauthorized if user is not the host nor a admin" do
      @user.update_attributes(:is_admin => false)
      other_user = create(:user)
      Event.should_receive(:find).with(@event[:id].to_s).and_return(@event)

      @event.should_receive(:host).and_return other_user

      post :cancel, :id => @event.id

      response.status.should == 401
    end
  end

  describe "POST attend" do

    before :each do
      @event.get_together.required_user_details = {
          first_name: :optional,
          last_name: :optional,
          mobile_number: :optional,
          home_number: :optional,
          street_address: :optional,
          suburb: :optional,
          postcode_number: :optional,
          country_iso: :hidden
      }
    end

    it "should render an error when a required value is not supplied" do
      @event.get_together.required_user_details[:last_name] = :required
      @event.get_together.save!
      post :attend, :id => @event.id, :user => {:email => "jabba@thehutt.com"}
      assigns[:user].errors[:last_name].first.should == "can't be blank"
      response.should render_template('show')
    end

    it "should create a new user and add them as an attendee" do
      post :attend, :id => @event.id, :user => {:email => "jabba@thehutt.com"}

      User.find_by_email('jabba@thehutt.com').should_not be_nil
      @event.reload
      @event.attendees.size.should == 1
      @event.attendees.first.email.should == 'jabba@thehutt.com'
      flash[:notice].should include("Thanks for attending")
    end

    it 'should display success message when user with duplicate email exception is raised' do
      e = ActiveRecord::RecordNotUnique.new('blah','potato')
      User.should_receive(:find_or_initialize_by_email).and_raise(e)
      post :attend, :id => @event.id, :user => {:email => 'ned@flanders.com'}
      flash[:notice].should include('Thanks for attending')
    end

    it "should redirect to redirect url when configured by admin" do
      @event.get_together.redirect_url = 'http://www.google.com'
      @event.get_together.save!

      post :attend, :id => @event.id, :user => {:email => "jabba@thehutt.com"}
      response.should redirect_to('http://www.google.com')
    end

    it "should redirect to event page when redirect url not configured by admin" do
      post :attend, :id => @event.id, :user => {:email => "jabba@thehutt.com"}
      response.should redirect_to(event_path(@event.friendly_id))
    end

    it "should redirect to event page when redirect url is removed by admin" do
      @event.get_together.redirect_url = ''
      @event.get_together.save!

      post :attend, :id => @event.id, :user => {:email => "jabba@thehutt.com"}
      response.should redirect_to(event_path(@event.friendly_id))
    end

    it "should acknowledge when a user is already registered for the event" do
      user = create(:user, :email => "jabba@thehutt.com")
      @event.add_attendee!(user)
      post :attend, :id => @event.id, :user => {:email => user.email}

      response.should redirect_to(event_path(@event.friendly_id))
      flash[:notice].should include("already registered")
    end

    it "should redirect to the configured redirect url when already registered for the event" do
      @event.get_together.redirect_url = 'http://www.google.com'
      @event.get_together.save!
      user = create(:user, :email => "jabba@thehutt.com")
      @event.add_attendee!(user)
      post :attend, :id => @event.id, :user => {:email => user.email}
      response.should redirect_to('http://www.google.com')
    end

    it "should reject invalid email addresses (for no JS case)" do
      post :attend, :id => @event.id, :user => {:email => "dafasfddsf"}
      assigns[:user].errors[:email].first.should == "is invalid"
    end

    it "updates stored user details" do
      user = create(:user, :email => "jabba@thehutt.com", first_name: 'Original')
      post :attend, :id => @event.id, :user => {:email => "jabba@thehutt.com", :first_name => 'New'}
      user.reload
      user.first_name.should == 'New'
    end

    it "should create a registered to attend activity event" do
      user = create(:user, :email => "salacious@crumb.com")
      email = create(:email)
      t = EmailTrackingToken.encode user.id, email.id
      UserActivityEvent.should_receive(:registered_to_attend!).with(user, @event, email, nil)
      post :attend, :id => @event.id, :user => {:email => user.email}, :t => t
    end

    it 'should record the acquisition source when a token is present' do
      email = "herd.mcgerkinshaw@getup.org.au"
      acquisition_source = create(:acquisition_source)
      t = EmailTrackingToken.encode_with_source acquisition_source.id
      post :attend, :id => @event.id, :user => {:email => email}, :t => t
      user = User.find_by_email email
      expect(user.user_activity_events.subscriptions.last.acquisition_source).to eq(acquisition_source)
      expect(user.user_activity_events.actions_taken.last.acquisition_source).to eq(acquisition_source)
    end

  end

  describe "POST cancel_attendance" do
    it "should cancel the user's attendance and redirect to the event's page" do
      user = create(:user, :email => "jabba@thehutt.com")
      @event.add_attendee!(user)
      post :cancel_attendance, :id => @event.id, :user => {:email => user.email}
      
      response.should redirect_to(event_path(@event.friendly_id))
      flash[:notice].should == "Your attendance to this event has been canceled."
    end

    it "should redirect to the events page with no message if the user is not attending the event" do
      user = create(:user, :email => "jabba@thehutt.com")
      post :cancel_attendance, :id => @event.id, :user => {:email => user.email}

      response.should redirect_to(event_path(@event.friendly_id))
      flash[:notice].should be_nil
    end
  end

  describe "POST messages to attendees", delay_jobs: false do

    it 'should send an email to all attendees and redirect to the event page if the current user is the host' do
      user = create(:user, :email => 'jabba@thehutt.com')
      @event.add_attendee!(user)
      @event.stub(:host).and_return @user
      Event.stub(:find).and_return(@event)
      post :message_attendees, :id => @event.id, :message => 'message to be sent'
      response.should redirect_to(event_path(@event.friendly_id))
      flash[:notice].should eql 'Your message is in the process of being sent.'
      ActionMailer::Base.deliveries.last.should have_body_text(/message to be sent/)
    end

    it "should redirect to the event page with no message if event is empty" do
      @event.should_receive(:host).and_return @user
      Event.should_receive(:find).twice.with(@event[:id].to_s).and_return(@event)
      post :message_attendees, :id => @event.id, :message => "message to be sent"
      response.should redirect_to(event_path(@event.friendly_id))
      flash[:notice].should eql nil
    end

    context 'host is from invalid email domain' do
      it 'should rewrite the from address and set reply-to' do
        user = create(:user, :email => 'jabba@thehutt.com')
        @event.add_attendee!(user)
        @user.update_attributes!(email: 'host@yahoo.com')
        @event.host = @user
        @event.confirmed_at = Time.now
        @event.save!
        AppConstants.stub(:invalid_from_email_domain).and_return(['yahoo.com', 'aol.com'])
        post :message_attendees, :id => @event.id, :message => 'message to be sent'
        ActionMailer::Base.deliveries.last.from.should == ['host@yahoo.com.invalid']
        ActionMailer::Base.deliveries.last.reply_to.should == ['host@yahoo.com']
      end
    end
  end

  describe "#show" do
    it "should return 404 when requesting an unknown id" do
      get :show, :id => "i-am-a-made-up-id"
      response.code.should == "404"
    end

    it "should display an event" do
      gt = create(:get_together)
      e = create(:event, get_together: gt)
      get :show, id: e
      assigns(:event).should == e
    end

    context "themes" do
      it "should fall back to app theme by default" do
        e = create(:event, get_together: create(:get_together))
        get :show, id: e
        response.should render_template(:layout => 'layouts/application')
      end

      it "should render custom theme" do
        get_together = create(:get_together)
        get_together.theme = Theme.create(:name=>'no_branding', :display_name=>'No Brand')
        get_together.save!
        e = create(:event, get_together: get_together)
        get :show, id: e
        response.should render_template(:layout => 'layouts/themes/no_branding')
      end
    end
  end
end
