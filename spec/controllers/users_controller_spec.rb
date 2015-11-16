require File.expand_path(File.dirname(__FILE__) + "../../spec_helper")

describe UsersController do
  render_views
  describe "lookup a user for a page" do
    describe "validate email" do
      before(:each) do
        @page = create(:page_with_parent, :required_user_details => {:first_name => :required})
      end

      it "should return a thank you message if the user exists and all required details are present" do
        user = create(:user, :email => 'bruce@example.com', :first_name => "Bruce").save
        get :lookup, {:email => 'BRUCE@EXAMPLE.COM', :page_id => @page.id}
        response.body.should =~ /Thanks for entering your email./
      end

      it "should return a welcome message if the user doesn't exist" do
        Rails.cache.delete("users/bruce@example.com")
        get :lookup, {:email => 'bruce@example.com', :page_id => @page.id}
        response.body.should =~ /Welcome!/
      end

      it "should return an error message if not a valid e-mail address" do
        user = create(:user, :email => 'bruce@example.com', :first_name => "Bruce")
        get :lookup, {:email => 'bruce@example', :page_id => @page.id}
        response.body.should =~ /This is not a valid email address./
      end

      it "should return an error message if an empty e-mail address" do
        user = create(:user, :email => 'bruce@example.com', :first_name => "Bruce")
        get :lookup, {:email => '', :page_id => @page.id}
        response.body.should =~ /Please enter your email address./

        get :lookup, {:email => nil, :page_id => @page.id}
        response.body.should =~ /Please enter your email address./
      end

      it "should accept emails with leading or trailing spaces" do
        user = create(:user, :email => 'bruce@example.com', :first_name => "Bruce")
        get :lookup, {:email => '  bruce@example.com   ', :page_id => @page.id}
        response.body.should =~ /Thanks for entering your email./
      end
    end

    describe "refresh/required fields" do
      before(:each) do
        @page = create(:page_with_parent)
      end

      it "should ask to fill entries to user if fields are null and set to required" do
        @page.required_user_details = {:first_name => :required, :last_name => :required,
                                       :postcode_number => :required, :mobile_number => :required,
                                       :home_number => :required, :street_address => :required,
                                       :suburb => :required, :country_iso => :required}
        user = create(:user, :email => 'bruce@example.com', :first_name => "Bruce", :last_name => "Lee")
        Rails.cache.write(User.generate_cache_key("bruce@example.com"), user)
        Rails.cache.write(Page.generate_cache_key(@page.id), @page)

        get :lookup, {:email => 'bruce@example.com', :page_id => @page.id}

        json = JSON.parse(response.body)

        ['first_name', 'last_name'].each do |field|
          user[field].should_not be_nil
          json['user'][field].should be false
        end

        ['postcode_number', 'mobile_number', 'home_number', 'street_address', 'suburb', 'country_iso'].each do |field|
          user[field].should be_nil
          json['user'][field].should be true
        end
      end

      it "should ask for field in user if field is set to refresh" do
        @page.required_user_details = {:first_name => :refresh, :last_name => :refresh,
                                       :postcode_number => :refresh, :mobile_number => :refresh,
                                       :home_number => :refresh, :street_address => :refresh,
                                       :suburb => :refresh, :country_iso => :refresh}
        user = create(:user, :email => 'bruce@example.com', :first_name => "Bruce",
                              :last_name => "Lee", :home_number => "98765432",
                              :mobile_number => "0492811111", :street_address => "1/2 random st",
                              :suburb => "Notonplanet", :postcode_number => "1200", :country_iso => "BR")
        Rails.cache.write(User.generate_cache_key("bruce@example.com"), user)
        Rails.cache.write(Page.generate_cache_key(@page.id), @page)

        get :lookup, {:email => 'bruce@example.com', :page_id => @page.id}

        json = JSON.parse(response.body)

        ['first_name', 'last_name', 'postcode_number', 'mobile_number', 'home_number', 'street_address', 'suburb', 'country_iso'].each do |field|
          json['user'][field].should be true
        end
      end


      it 'uses get together user details requirements when get together id is supplied' do
        get_together = create(:get_together, required_user_details: {:first_name => :required, :last_name => :optional, :home_number => :required, :mobile_number => :optional})
        user = create(:user, :email => 'bruce@example.com', :first_name => "Bruce", :last_name => "Lee", :home_number => '', :mobile_number => '')
        get :lookup, {:email => 'bruce@example.com', :get_together_id => get_together.id}
        json = JSON.parse(response.body)
        json['user']['first_name'].should be false
        json['user']['last_name'].should be false
        json['user']['home_number'].should be true
        json['user']['mobile_number'].should be true
      end
    end

    describe "json response" do

      let :required_user_details do {
        :first_name=> :required,
        :last_name => :required,
        :postcode_number => :optional,
        :mobile_number => :optional,
        :home_number => :hidden,
        :street_address => :hidden,
        :suburb => :hidden,
        :country_iso => :hidden,
      } end

      let :page do create(:page_with_parent, required_user_details: required_user_details ) end
      let :user do create :user,
         email: 'some@email.com',
         first_name: 'First',
         last_name: 'Last',
         mobile_number: 'Mobile',
         home_number: 'Home',
         street_address: 'Street',
         suburb: 'Suburb',
         postcode: create(:postcode, number: '2222'),
         country_iso: 'XX',
         quick_donate_trigger_id: 'THE_TRIGGER'
      end

      before :each do
        create(:donation, user: user, card_number: '4111 1111 1111 1111', trigger_id: 'THE_TRIGGER')
      end

      context "with new user" do
        before :each do
          remove_quickdonate_cookie
          get :lookup, email: 'nonexistent@user.com', page_id: page.id
          @response = JSON.parse(response.body)
        end

        it "requires user attributes as per page setup (optional and required)" do
          user = @response['user']
          user['first_name'].should be true
          user['last_name'].should be true
          user['mobile_number'].should be true
          user['postcode_number'].should be true
          user['home_number'].should be false
          user['street_address'].should be false
          user['suburb'].should be false
          user['country_iso'].should be false
        end

      end

      include QuickdonateHelper

      context "without quick donate session" do
        before :each do
          remove_quickdonate_cookie
          get :lookup, email: user.email, page_id: page.id
          @response = JSON.parse(response.body)
        end

        it "requires missing attributes for user (none, they are all already supplied)" do
          user = @response['user']
          user['first_name'].should be false
          user['last_name'].should be false
          user['mobile_number'].should be false
          user['postcode_number'].should be false
          user['home_number'].should be false
          user['street_address'].should be false
          user['suburb'].should be false
          user['country_iso'].should be false
        end

        it "does not return quickdonate account information" do
          @response['quick_donate_card_info'].should be_nil
        end

      end

      context "with quick donate cookie" do

        before :each do
          enable_quickdonate_cookie_for(user)
          get :lookup, email: user.email, page_id: page.id
          @response = JSON.parse(response.body)
        end

        it "returns quickdonate account information" do
          @response['quick_donate_card_info'].should include 'Visa: ****1111'
        end
      end
    end
  end

  def user_does_not_have_field(*fields)
    fields.each {|field|
      @response['user'][field].should be_blank
    }
  end

  def json_does_not_have_fields(*fields)
    fields.each {|field|
      @response[field].should be_blank
    }

  end

  def json_has_fields(fields)
    fields.each{|attr, value|
      @response[attr].should == value
    }
  end

  describe "user lookup as part of a donation of $250 dollars or more" do
    let(:page){ create(:page_with_parent, required_user_details: {street_address: :hidden, suburb: :hidden, country_iso: :hidden}) }
    let(:user){ create(:user) }

    it "should set all address details fields to required" do
      get :lookup, email: user.email, page_id: page.id, donation_amount: '250'
      json = JSON.parse(response.body)
      ['postcode_number', 'street_address', 'suburb', 'country_iso'].each do |field|
        json['user'][field].should be true
      end
      json['address_required'].should be true
    end
  end

  describe "updating a user" do

    let(:user) { create(:user, email: 'bruce@example.com', first_name: "Bruce", country_iso: 'AU') }

    before :each do
      sign_in user
    end

    it "should update the user's detail'" do
      put :update, :user => {:first_name => "Leo", :country_iso => "AX"}

      response.should be_success
      user.reload
      user.first_name.should eql "Leo"
      user.country_iso.should eql "AX"
    end

    it "should validate email and return a json error" do
      put :update, :user => {:email => "something"}

      response.should_not be_success
      response.body.to_s.should eql "{\"email\":[\"is invalid\"]}"
    end

    it "should not allow updating the 'is_admin' attribute" do
      put :update, :user => {:first_name => "bob", :is_admin => true}

      response.should be_success
      user.reload
      user.first_name.should eql "bob"
      user.is_admin.should be false
    end

    it 'should not update user when user is logged out' do
      sign_out user
      put :update, :user => {:first_name => "Leo", :country_iso => "AX"}
      response.should_not be_success
    end

    it "should ignore id and should always updates logged in user's attributes" do
      other_user = create(:user)
      put :update, {:id => other_user.id, :user => {:first_name => "Leo", :country_iso => "AX"}}
      response.should be_success
      user.reload
      user.first_name.should eql "Leo"
      user.country_iso.should eql "AX"
    end
  end

  describe 'setup_quickdonate' do

    before :each do
      @donation = create(:donation, user: create(:user))
      session[:action_id] = @donation.id
    end

    it "uses donation from session to setup quickdonate" do
      Donation.stub(:find).with(@donation.id).and_return(@donation)
      @donation.should_receive(:use_for_quickdonate)
      post :setup_quickdonate
    end

    it "should keep user id in session when user is logged in" do
      sign_in @donation.user
      post :setup_quickdonate
      cookies.signed[:quick_donate_user_id].should == @donation.user.id
    end

    it "should keep user id in session when user is not logged in" do
      post :setup_quickdonate
      cookies.signed[:quick_donate_user_id].should == @donation.user.id
    end
  end

  describe '#logout_quickdonate' do
    let!(:quick_donate_cookie) { cookies[:quick_donate_user_id] = 1 }
    before { sign_in create(:user) }

    context 'with post' do
      before { post :logout_quickdonate }
      it { response.should redirect_to(root_path) }
      it { cookies[:quick_donate_user_id].should be_nil }
    end

    context 'with ajax' do
      before { xhr :post, :logout_quickdonate }
      it { response.should be_success }
      it { cookies[:quick_donate_user_id].should be_nil }
    end
  end

  describe 'address validation' do
    context 'address' do
      it 'should return expected result when supplying the address parameter' do
        return_string = 'return string'
        controller.send(:address_service).stub(:lookup_address_using_partial_address).with('test address').and_return(return_string)
        get :address, {:initial_address_query => 'test address'}
        response.body.should include return_string
      end

      it 'should return expected result when supplying the search_result_id parameter' do
        return_string = 'return string'
        controller.send(:address_service).stub(:lookup_address_using_search_result_id).with('an id').and_return(return_string)
        get :address, {:drill_down_search_result_id => 'an id'}
        response.body.should include return_string
      end

    end
  end

  describe ".user_email_story" do
    let(:user){ create(:user) }
    let(:token){ EmailTrackingToken.encode(user.id, create(:email).id) }
    let(:content_module){ create(:email_targets_module) }

    context "with a valid user id and content module id passed" do
      let(:message){ "Waiting times in Emergency  ....  five hrs before being attended for " +
                  "my brother-in-law who had a kidney removed and is 81yrs old!\n" + 
                  "NO complaints once attended by staff." }
      let(:body_with_signature){ "#{message}\n\n\nLiesma Lieknis\nliesmalieknis@yahoo.com.au\nNSW 2026" }
      let!(:user_email){ create(:user_email, body: body_with_signature, user: user, content_module: content_module) }

      it "should return the body of the story" do
        get :user_email_story, {t: token, cm: content_module.id}
        expect(JSON.parse(response.body)).to eq({"story" => message})
      end
    end
  end

  describe ".not_you" do
    let!(:secure_user){ create(:user) }
    let!(:page){ create(:page_with_parent, name: 'showcase') }
    let!(:token){ 'XX' }
    before{ cookies.signed[:user_id] = secure_user.id }

    it "should clear the cookie" do
      post :not_you, page_id: page.id
      expect(cookies.signed[:user_id]).to be_nil
    end

    it "should record an event" do
      post :not_you, page_id: page.id
      expect(
        secure_user.user_activity_events
          .where(activity: UserActivityEvent::Activity::OPT_OUT_ONE_CLICK)
          .where(page_id: page.id)
          .count
      ).to eq(1)
    end

    it "should redirect back to the page, removing the token" do
      post :not_you, page_id: page.id, t: token
      expect(response).to be_success
      expect(JSON.parse(response.body)['url']).to eq('http://test.host/campaigns/dummy-campaign-name/dummy-page-sequence-name/showcase')
    end
  end
end
