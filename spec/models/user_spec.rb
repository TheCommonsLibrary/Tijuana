require File.expand_path(File.dirname(__FILE__) + "../../spec_helper")

describe User do

  describe "#did_subscribe_during?" do
    context "new user" do
      before(:each) do
        @user = User.new(email: 'foo@blah.com')
      end

      it "no save" do
        @user.did_subscribe_during? do
          @user.is_member = true
        end.should be false
      end

      it "no subscribe" do
        @user.did_subscribe_during? do
          @user.is_member = false
          @user.save!(validate: false)
        end.should be false
      end

      it "subscribes" do
        @user.did_subscribe_during? do
          @user.is_member = true
          @user.save!(validate: false)
        end.should be true
      end
    end

    context "existing member" do
      before(:each) do
        @user = create(:user, :is_member => true)
      end

      it "no save" do
        @user.did_subscribe_during? do
          @user.is_member = true
        end.should be false
      end

      it "no subscribe" do
        @user.did_subscribe_during? do
          @user.is_member = false
          @user.save!(validate: false)
        end.should be false
      end

      it "already subscribed" do
        @user.did_subscribe_during? do
          @user.is_member = true
          @user.save!(validate: false)
        end.should be false
      end
    end

    context "existing non-member" do
      before(:each) do
        @user = create(:user, :is_member => false)
      end

      it "no save" do
        @user.did_subscribe_during? do
          @user.is_member = true
        end.should be false
      end

      it "no subscribe" do
        @user.did_subscribe_during? do
          @user.is_member = false
          @user.save!(validate: false)
        end.should be false
      end

      it "subscribed" do
        @user.did_subscribe_during? do
          @user.is_member = true
          @user.save!(validate: false)
        end.should be true
      end
    end

  end


  describe "#subscribing?" do
    it "new user" do
      User.new.subscribing?.should be true
      User.new(is_member: true).subscribing?.should be true
      User.new(is_member: false).subscribing?.should be false
    end

    it "existing user on load" do
      create(:user, is_member: true).subscribing?.should be false
      create(:user, is_member: false).subscribing?.should be false
    end

    it "existing user who joins" do
      u = create(:user, is_member: false)
      u.is_member = true
      u.subscribing?.should be true
    end
  end

  describe "#highest_previous_donation_amount" do

    it "returns nil if no donation present" do
      create(:user).highest_previous_donation_amount.should be_nil
    end

    def user_with_donation(amount_in_cents)
      user = create(:user)
      add_donation(user, amount_in_cents)
      user
    end

    def add_donation(user, amount_in_cents, transaction_attributes={}, donation_attributes={})
      donation = create(:donation, {user: user, frequency: 'one_off'}.merge(donation_attributes))
      transaction = create(:transaction, {donation: donation, amount_in_cents: amount_in_cents}
      .merge(transaction_attributes))
    end

    it "returns highest valid donation amount in last 18 months for correct user" do
      user = user_with_donation(4400)
      add_donation(user, 5500, successful: true, refunded: false, created_at: 17.months.ago)
      add_donation(user, 6500, successful: false, refunded: false, created_at: 17.months.ago)
      add_donation(user, 7500, successful: true, refunded: true, created_at: 17.months.ago)
      add_donation(user, 8500, successful: true, refunded: false, created_at: 18.months.ago - 1.day)
      user.highest_previous_donation_amount.should == 55
    end

    it "for correct user" do
      user1 = user_with_donation(4400)
      user2 = user_with_donation(9900)
      user1.highest_previous_donation_amount.should == 44
    end

    it "rounds to nearest dollar" do
      user = user_with_donation(5555)
      user.highest_previous_donation_amount.should == 56

      user = user_with_donation(5520)
      user.highest_previous_donation_amount.should == 55
    end

    it "ignores negative donations" do
      user_with_donation(-500).highest_previous_donation_amount.should be_nil
    end

    it "ignores recurring donations" do
      user = user_with_donation(500)
      add_donation(user, 800, {}, frequency: 'weekly')
      add_donation(user, 900, {}, frequency: 'monthly')
      add_donation(user, 1800, {}, frequency: 'yearly')
      user.highest_previous_donation_amount.should == 5
    end

  end

  describe "knowing whether a details field has been entered previously" do
    it "should return true if the field has been persisted" do
      user = create(:user, :first_name => "Bob")
      user.value_saved?(:first_name).should be true
    end

    it "should return false if no record has been saved" do
      user = build(:user, :first_name => "Bob")
      user.value_saved?(:first_name).should be false
    end

    it "should return false if the value of the field is blank" do
      user = create(:user, :first_name => "", :last_name => nil)
      user.value_saved?(:first_name).should be false
      user.value_saved?(:last_name).should be false
    end

    it "should return false if the field is dirty" do
      user = create(:user, first_name: 'first')
      user.first_name = 'a new first name'
      user.value_saved?(:first_name).should be false
    end
  end

  describe "names" do
    it "should have a titlecased, HTML safe greeting for emails etc." do
      create(:user, :first_name => "ferhandez").greeting.should == "Ferhandez"
      create(:user, :first_name => nil).greeting.should == nil
    end

    it "should have a full name, or Unknown Username if neither first nor last names are present" do
      create(:user, :first_name => "rico").full_name.should == "Rico"
      create(:user, :last_name => "ferhandez").full_name.should == "Ferhandez"
      create(:user, :first_name => "rico", :last_name => "ferhandez").full_name.should == "Rico Ferhandez"
      create(:user, :first_name => "", :last_name => "").full_name.should == "Unknown Username"
    end
  end

  describe "#email_field" do

    context "user with no first name" do
      let(:user_with_last_name) { create(:user, first_name: nil, last_name: 'Jones', email: 'bobby@jones.com.au') }
      let(:user_with_no_name) { create(:user, first_name: nil, last_name: nil, email: 'timmy@timbob.co.nz') }

      specify { user_with_last_name.email_field.should == 'bobby@jones.com.au' }
      specify { user_with_no_name.email_field.should == 'timmy@timbob.co.nz' }
    end

    context "user with first name" do
      let(:user_with_first_name) { create(:user, first_name: 'Jimmy', last_name: nil, email: 'jimmy@emailsolutions.com.au') }
      let(:user_with_full_name) { create(:user, first_name: 'Kelly', last_name: 'Kelson', email: 'kelly@kellykelson.net') }

      specify { user_with_first_name.email_field.should == 'Jimmy <jimmy@emailsolutions.com.au>' }
      specify { user_with_full_name.email_field.should == 'Kelly Kelson <kelly@kellykelson.net>' }
    end

    context "user with double quotes in name" do
      let(:user_with_double_quotes) { create(:user, first_name: 'Kelly', last_name: 'O"Bryen', email: 'kelly@obryen.net') }
      specify { user_with_double_quotes.email_field.should == "Kelly O'Bryen <kelly@obryen.net>" }
    end
  end

  describe "validation" do
    before(:each) do
      @required_user_details = {:first_name => :required, :last_name => :optional, :home_number => :required}
      @tw_office_postcode = create(:postcode_of_tw_office)
      @postcode_for_darwin = create(:postcode_for_darwin)
    end

    it "must have a valid email address" do
      User.new(:email => "me@email.com").should be_valid
      User.new(:email => nil).should_not be_valid
      User.new(:email => "me@email").should_not be_valid
      User.new(:email => "trevor/parmenter@sydney.edu.au").should be_valid
      User.new(:email => "Abc.example.com").should_not be_valid
    end

    it "must have a valid post code" do
      User.new(:email => "me@email.com", :postcode_number => @tw_office_postcode.number, :country_iso => "AU").should be_valid
      User.new(:email => "me@email.com", :postcode_number => "800", :country_iso => "AU").should be_valid
      User.new(:email => "me@email.com", :postcode_number => nil, :country_iso => "AU").should be_valid
      User.new(:email => "me@email.com", :country_iso => "AU").should be_valid
      User.new(:email => "me@email.com", :postcode_number => "123", :country_iso => "AU").should_not be_valid
      User.new(:email => "me@email.com", :postcode_number => "abc", :country_iso => "AU").should_not be_valid

      User.new(:email => "me@email.com", :postcode_number => "abc", :country_iso => "AO").should be_valid
      User.new(:email => "me@email.com", :postcode_number => "12ABC", :country_iso => "AO").should be_valid
      User.new(:email => "me@email.com", :postcode_number => "123", :country_iso => "AO").should be_valid
      User.new(:email => "me@email.com", :postcode_number => nil, :country_iso => "AO").should be_valid
      User.new(:email => "me@email.com", :country_iso => "AO").should be_valid
    end

    it "should have unique emails" do
      User.create(:email => "person@email.com").should be_valid
      User.new(:email => "person@email.com").should_not be_valid
    end

    it "should strip emails" do
      User.create(:email => " person@email.com ").email.should == "person@email.com"
    end

    it "must have all fields required by page" do
      user = create(:user, :first_name => "Sanchez", :last_name => "Bob", :home_number => "")
      user.required_user_details = @required_user_details
      user.should_not be_valid
      user.home_number = '90632781'
      user.should be_valid
    end

    it "should not complain if optional fields are empty" do
      user = create(:user, :first_name => "Sanchez", :last_name => "", :home_number => "0009990002")
      user.required_user_details = @required_user_details
      user.should be_valid
    end

    it "validates max lengths for all supplied fields" do
      user = create(:user, :first_name => "Sanchez", :last_name => "Bob")
      user.required_user_details = @required_user_details

      user.home_number = "X" * 2000
      user.should_not be_valid
      user.home_number = '90632781'
      user.should be_valid

      user.last_name = "Y" * 2000
      user.should_not be_valid
      user.last_name = 'Bobson'
      user.should be_valid
    end

    it "should validate password is not blank and password confirmation matches password when create a new password" do
      User.new(:email => "me@email.com",
               :password => 'some_password',
               :password_confirmation => 'some_password'
      ).should be_valid

      User.new(:email => "me@email.com",
               :password => '',
               :password_confirmation => ''
      ).error_on(:password).first.should eql "can't be blank"

      User.new(:email => "me@email.com",
               :password => 'some_password',
               :password_confirmation => 'some_other_password'
      ).error_on(:password).first.should eql "doesn't match confirmation"
    end
  end

  describe "having a postcode" do
    before(:each) do
      @fitzroy = Postcode.create!(:number => "3065", :state => 'VIC', :latitude => -37.796684, :longitude => 144.980693)
    end

    it "looks up the postcode when #postcode_number is set" do
      u = User.new(:postcode_number => "3065")
      u.postcode.should == @fitzroy
    end

    it "renders number from postcode when #postcode_number is called" do
      u = User.new(:postcode => @fitzroy)
      u.postcode_number.should == "3065"
    end

    it "renders state from postcode when #postcode_state is called" do
      u = User.new(:postcode => @fitzroy)
      u.postcode_state.should == "VIC"
    end

    it "does not require a postcode" do
      u = User.new(:postcode => nil)
      u.postcode_number.should == nil
    end

    it "validates presence of postcode" do
      u = User.new(:email => "someone@somewhere.com", :postcode_number => "")
      u.required_user_details = {:postcode_number => :refresh}
      u.should_not be_valid
      u.postcode_number = "3065"
      u.should be_valid
    end
  end

  describe "having old tags" do
    it "should strip whitespace from the old tags on save" do
      u = create(:user, :old_tags => " red, blue ")
      u.save!
      u.reload
      u.old_tags.should == "red,blue"
    end
  end

  describe ".merge_tags!" do
    let!(:user){ create :user }

    it "should merge tags and save" do
      user.update_attributes :tag_list => ["red", "blue"]
      user.merge_tags! ['green', 'blue']
      user.reload
      user.tag_list.should == ["red", "blue", "green"]
    end

    context "with a ActiveRecord::RecordNotUnique error" do

      it "should merge tags and save" do
        user.update_attributes! :tag_list => ["red", "blue"]
        call_count = 0
        expect(user).to receive(:update_attributes!).twice.and_wrap_original{|m, *args|
          if call_count.zero?
            call_count += 1
            raise ActiveRecord::RecordNotUnique.new('test', 'test')
          else
            m.call(*args)
          end
        }
        user.merge_tags! ['green', 'blue']
        user.reload
        user.tag_list.should == ["red", "blue", "green"]
      end
    end
  end

  describe "having notes" do
    it "should save the notes field" do
      u = User.new(:email => "someone@somewhere.com", :notes => "Some random notes")
      u.notes.should == "Some random notes"
    end

    it "should not require a notes field" do
      u = User.new(:email => "someone@somewhere.com")
      u.should be_valid
    end
  end

  describe "subscription callbacks" do
    before(:each) do
      @user = build(:user)
    end

    it "should subscribe a user when a new member is created" do
      @user.is_member = true
      @user.save!
      @user.should have(1).user_activity_events
      @user.user_activity_events.first.activity.should == :subscribed
    end

    it "should not subscribe a user when they do not wish to be a member" do
      @user.is_member = false
      @user.save!
      @user.should have(0).user_activity_events
    end
  end

  describe "capturing information when responding to an ask" do

    it "records the ask, page, campaign info on the subscribed activity event" do
      ask = create(:email_mp_module)
      page = create(:page_with_parent)
      email = create(:email)
      ContentModuleLink.create!(:content_module => ask, :page => page)
      user = User.new
      user.validate_and_always_save_email({}, {"email" => "someone@else.com", "is_member" => "true"}, page, ask, email)
      uae = user.user_activity_events.first
      uae.activity.should == :subscribed
      uae.email.should == email
      uae.content_module.should == ask
      uae.content_module_type.should == "EmailMPModule"
      uae.page.should == page
      uae.page_sequence.should == page.page_sequence
      uae.campaign.should == page.page_sequence.campaign
    end

    it "should persist email even when other details are not valid" do
      user = User.new(email: 'example@example.com')
      required_details = {:last_name => :required}
      user.validate_and_always_save_email(required_details, {"email" => "example@example.com", "first_name" => "first"}, nil, nil, nil)

      user.should be_persisted
      user.should_not be_valid
      persisted_user = User.find_by_email(user.email)
      persisted_user.email.should == 'example@example.com'
      persisted_user.first_name.should be_nil
    end

    it "should save user with trailing or leading space in email" do
      user = User.new(email: '  still@validuser.com  ')
      user.validate_and_always_save_email({first_name: :required}, {"email" => '  still@validuser.com  '}, nil, nil, nil)

      user.should be_persisted
      persisted_user = User.find_by_email(user.email)
      persisted_user.email.should == 'still@validuser.com'
    end

    it "should not save user with invalid email when other details are also not valid" do
      user = User.new(email: 'invalid@useremail')
      user.validate_and_always_save_email({first_name: :required}, {"email" => "invalid@useremail"}, nil, nil, nil)

      user.should_not be_persisted
      persisted_user = User.find_by_email(user.email)
      persisted_user.should be_nil
    end

    it "should not update invalid user" do
      first_name = 'bart'
      last_name = 'simpson'
      user = create(:user, first_name: first_name, last_name: last_name)

      user.validate_and_always_save_email({first_name: :required}, {"email" => user.email, "first_name" => "", "last_name" => "", "is_member" => "false"}, nil, nil, nil)
      user.first_name.should be_blank
      user.last_name.should be_blank
      persisted_user = User.find_by_email(user.email)
      persisted_user.first_name.should eql first_name
      persisted_user.last_name.should eql last_name
      persisted_user.is_member.should be true
      user.should_not be_valid
    end

    it "should not update when required postcode not supplied" do
      postcode_number = '2000'
      create(:postcode, number: postcode_number)
      user = create(:user, first_name: "bart", last_name: "simpson", postcode_number: "#{postcode_number}")
      user.postcode_number.should eql postcode_number
      user.postcode.should_not be_nil

      user.validate_and_always_save_email({postcode_number: :required}, {"email" => user.email, "postcode_number" => ""}, nil, nil, nil)
      user.postcode_number.should be_blank
      persisted_user = User.find_by_email(user.email)
      persisted_user.postcode_number.should eql postcode_number
      user.should_not be_valid
    end

    it "should ignore blank field when it is not required" do
      first_name = 'some one'
      user = create(:user, first_name: first_name)
      user.validate_and_always_save_email({}, {"email" => user.email, "first_name" => ""}, nil, nil, nil)
      persisted_user = User.find_by_email(user.email)
      persisted_user.first_name.should eql first_name
      user.should be_valid
    end

    it "should only create one subscribe event when saving" do
      first_name = 'firstname'
      user = build(:user, first_name: first_name)
      user.validate_and_always_save_email({}, {"email" => user.email, "first_name" => ""}, nil, nil, nil)
      uae = user.user_activity_events.all
      uae.count.should == 1
      uae.first.activity.should == :subscribed
    end
  end

  describe '#save_with_source_info!' do
    it 'records the ask, page, email and source on the subscribed activity event' do
      ask = create(:email_mp_module)
      page = create(:page_with_parent)
      email = create(:email)
      source = 'facebook'
      acquisition_source = create(:acquisition_source)
      ContentModuleLink.create!(:content_module => ask, :page => page)
      user = User.new(email: 'test@example.com')
      user.save_with_source_info!(page, ask, email, source, acquisition_source)
      uae = user.user_activity_events.first
      uae.activity.should == :subscribed
      uae.email.should == email
      uae.content_module.should == ask
      uae.content_module_type.should == "EmailMPModule"
      uae.page.should == page
      uae.page_sequence.should == page.page_sequence
      uae.campaign.should == page.page_sequence.campaign
      uae.source.should == source
      uae.acquisition_source.should == acquisition_source
    end

    it 'throws exception when saving with invalid email' do
      ask = create(:email_mp_module)
      page = create(:page_with_parent)
      email = create(:email)
      source = 'facebook'
      ContentModuleLink.create!(:content_module => ask, :page => page)
      user = User.new(email: 'bademail')
      expect { user.save_with_source_info!(page, ask, email, source) }.to raise_error('Validation failed: Email is invalid')
    end
  end

  describe '#save_with_source' do
    it 'should set the supplied source on the uae subscribe record' do
      user = User.new(email: 'testuser@example.com')
      user.save_with_source('source')
      UserActivityEvent.find_by_user_id(user.id).source.should == 'source'
    end
  end

  describe "#unsubscribe" do
    before :each do
      @email = create(:email)
      @user = create(:user, :is_member => true, :is_agra_member => true)
    end

    describe "unsubscribe from getup" do
      it "should change member status to false and add an unsubscribed event" do
        @user.unsubscribe!

        @user.is_member?.should be false
        @user.is_agra_member?.should be true
        UserActivityEvent.where(user_id: @user.id, activity: 'unsubscribed').count.should == 1
        Unsubscribe.where(user_id: @user.id).count.should == 1
      end

      it "should change member status to false and add an unsubscribed activity event belonging to an email" do
        @user.unsubscribe!(@email)

        @user.is_member?.should be false
        @user.is_agra_member?.should be true
        uae = UserActivityEvent.where(user_id: @user.id, activity: 'unsubscribed')
        uae.count.should == 1
        uae.first.email.id.should == @email.id

        unsubscribe = Unsubscribe.where(user_id: @user.id)
        unsubscribe.count.should == 1
        unsubscribe.first.email_id.should == @email.id
      end

      it "should record the reason and specifics for unsubscribing" do
        @user.unsubscribe!(@email, false, 'other', 'i thought you were avaaz')

        @user.is_member?.should be false
        @user.is_agra_member?.should be true
        uae = UserActivityEvent.where(user_id: @user.id, activity: 'unsubscribed')
        uae.count.should == 1
        uae.first.email.id.should == @email.id

        unsubscribe = Unsubscribe.where(user_id: @user.id)
        unsubscribe.count.should == 1
        unsubscribe.first.email_id.should == @email.id
        unsubscribe.first.reason.should == 'other'
        unsubscribe.first.specifics.should == 'i thought you were avaaz'
      end
    end

    describe "unsubscribe from agra" do
      it "should change member status to false and record the unsubscribe event" do
        @user.unsubscribe!(nil, true)

        @user.is_member?.should be true
        @user.is_agra_member?.should be false
        UserActivityEvent.where(user_id: @user.id, activity: 'agra_unsubscribed').count.should == 1

        Unsubscribe.where(user_id: @user.id, community_run: true).count.should == 1
      end

      it "should change member status to false and add an unsubscribed activity event belonging to an email" do
        @user.unsubscribe!(@email, true)

        @user.is_member?.should be true
        @user.is_agra_member?.should be false
        uae = UserActivityEvent.where(user_id: @user.id, activity: 'agra_unsubscribed')
        uae.count.should == 1
        uae.first.email.should_not be_nil
        uae.first.email.id.should == @email.id

        unsubscribe = Unsubscribe.where(user_id: @user.id, community_run: true)
        unsubscribe.count.should == 1
        unsubscribe.first.email_id.should == @email.id
      end

      it "should record the reason and specifics for unsubscribing" do
        @user.unsubscribe!(@email, true, 'campaign', 'I never liked the reef')

        @user.is_member?.should be true
        @user.is_agra_member?.should be false
        uae = UserActivityEvent.where(user_id: @user.id, activity: 'agra_unsubscribed')
        uae.count.should == 1
        uae.first.email.should_not be_nil
        uae.first.email.id.should == @email.id

        unsubscribe = Unsubscribe.where(user_id: @user.id)
        unsubscribe.count.should == 1
        unsubscribe.first.email_id.should == @email.id
        unsubscribe.first.reason.should == 'campaign'
        unsubscribe.first.specifics.should == 'I never liked the reef'
      end
    end
  end

  describe 'set_low_volume!' do

    let(:user) { create(:user) }
    let(:email) { create(:email) }

    it "sets low volume flag" do
      user.set_low_volume!(email)
      user.should be_low_volume
    end

    it "creates UserActivityEvent" do
      UserActivityEvent.should_receive("requested_less_email!").with(user, email)
      user.set_low_volume!(email)
    end
  end

  describe "#find_email_addresses_by_user_ids" do
    it "should return a simple list of emails based on the given user ids " do
      user1 = create(:user, :email => 'leonardo@borges.com', :is_member => true)
      user2 = create(:user, :email => 'another@dude.com', :is_member => true)

      emails = User.find_email_addresses_by_user_ids([user1, user2].map(&:id))
      emails.size.should == 2
      emails.should include user1.email
      emails.should include user2.email
    end
  end

  describe "transactions" do
    before(:each) do
      @user = create(:user)
      @transaction_one = create(:transaction, :donation => create(:donation, :user => @user), :successful => true, :created_at => Time.local(2012, 04, 01))
      create(:transaction, :donation => create(:donation, :user => @user), :successful => false, :created_at => Time.local(2011, 07, 01))
    end

    it "should return all transactions" do
      Timecop.freeze(Date.parse('2012-04-30')) do
        @user.transactions.size.should eql 2
        @user.transactions[0].created_at.should eql @transaction_one.created_at
      end
    end

    it "should return only transactions for this user" do
      Timecop.freeze(Date.parse('2012-05-30')) do
        second_user = create(:user)
        create(:transaction, :donation => create(:donation, :user => second_user), :successful => true, :created_at => Time.local(2012, 04, 01))
        second_user.transactions.size.should eql 1
        second_user.transactions[0].donation.user.should eql second_user
      end
    end

    it "should return successful transactions" do
      Timecop.freeze(Date.parse('2012-04-30')) do
        create(:transaction, :donation => create(:donation, :user => @user), :successful => true, :created_at => Time.local(2012, 04, 01))
        @user.transactions.successful.size.should eql 2
        @user.transactions[0].successful.should eql @transaction_one.successful
      end
    end

  end

  describe "donations" do
    before(:each) do
      @user = create(:user)
    end

    it "should return all recurring donations " do
      create(:donation, :user => @user, :frequency => "one-off")
      create(:donation, :user => @user, :frequency => "weekly")
      create(:donation, :user => @user, :frequency => "monthly")

      @user.should have(2).recurring_donations
    end

    it "should return all flagged recurring donations" do
      create(:donation, :user => @user, :flagged_since => "2000-03-12 00:06:50")
      create(:donation, :user => @user, :flagged_since => "2000-03-13 00:06:50")
      create(:donation, :user => @user, :flagged_since => "2000-03-14 00:06:50")

      @user.should have(3).flagged_donations
    end
  end

  describe "After creation" do
    it "should update its random column" do
      u = create(:user)
      u.random.should_not be_nil
    end
  end

  describe 'after create' do
    context "with AppConstants.nationbuilder_sync_user_after_save = false" do
      before{ AppConstants.stub nationbuilder_sync_user_after_save: false }
      specify{ NationBuilder::SyncUserFromTjToNbService.should_not_receive(:new) }
      after{ create(:user) }
    end

    context "with AppConstants.nationbuilder_sync_user_after_save = true" do
      let!(:new_user){ build(:user) }
      before{ AppConstants.stub nationbuilder_sync_user_after_save: true }
      let(:mock_service_instance){ double('NationBuilder::SyncUserFromTjToNbService') }
      before{  NationBuilder::SyncUserFromTjToNbService.stub(:new).and_return(mock_service_instance) }

      it "should pass the user to an instance of NationBuilder::SyncUserFromTjToNbService" do
        mock_service_instance.should_receive(:sync!).with(new_user)
      end
      after{ new_user.save! }
    end
  end

  describe 'after save' do
    let!(:user){ create(:user) }
    context "with AppConstants.nationbuilder_sync_user_after_save = false" do
      before{ AppConstants.stub nationbuilder_sync_user_after_save: false }
      specify{ NationBuilder::SyncUserFromTjToNbService.should_not_receive(:new) }
      after{ user.save! }
    end

    context "with AppConstants.nationbuilder_sync_user_after_save = true" do
      before{ AppConstants.stub nationbuilder_sync_user_after_save: true }
      let(:mock_service_instance){ double('NationBuilder::SyncUserFromTjToNbService') }
      before{  NationBuilder::SyncUserFromTjToNbService.stub(:new).and_return(mock_service_instance) }
      it "should pass the user with changs to an instance of NationBuilder::SyncUserFromTjToNbService" do
        mock_service_instance.should_receive(:sync!).with(user, only_sync_these_attributes: ['last_name'])
      end
      after{ user.update_attributes! last_name: 'changed' }
    end
  end

  describe "#update_random_values" do
    it "should update all users' random values" do
      u = create(:user)
      u1 = create(:user)
      r = u.random
      r1 = u.random

      User.update_random_values

      u.reload
      u1.reload
      u.random.should_not eql r
      u1.random.should_not eql r1
    end
  end

  describe "#umbrella_user" do
    it "should return the offline donatinos umbrella user" do
      User.create(:first_name => "Umbrella", :last_name => "User", :email => 'offlinedonations@getup.org.au')

      "offlinedonations@getup.org.au".should eql User.umbrella_user.email
    end
  end

  describe "#transaction_history" do
    before(:each) do
      @user = create(:user)
      @donation = create(:donation, :card_number => PaymentGateways::CARD_SUCCESS, :frequency => "monthly", :user => @user)
      Transaction.create!(:donation => @donation, :successful => true)
      Transaction.create!(:donation => @donation, :successful => true)
      Transaction.create!(:donation => @donation, :successful => false)
    end

    it "should return a list of successful transactions" do
      @user.transaction_history({:from => 1.week.ago, :to => 1.weeks.from_now}).size.should eql 2
    end

    it "should allow the list of transactions to be filtered by date, in descending order" do
      one_month_from_now = 1.month.from_now
      next_month_transaction = Transaction.create!(:donation => @donation, :successful => true, :created_at => one_month_from_now)
      next_month_transaction_1 = Transaction.create!(:donation => @donation, :successful => true, :created_at => one_month_from_now + 1.day)

      transactions = @user.transaction_history(:from => one_month_from_now - 3.days, :to => one_month_from_now + 3.days)
      transactions.size.should eql 2
      transactions[0].id.should eql next_month_transaction_1.id
      transactions[1].id.should eql next_month_transaction.id
    end

    it 'returns a list of transactions at a specific transaction date' do
      transaction_time = Date.parse('26-04-2013').to_time
      Timecop.freeze(transaction_time) do
        Transaction.create!(:donation => @donation, :successful => true)
        Transaction.create!(:donation => @donation, :successful => true)
        Transaction.create!(:donation => @donation, :successful => false)
      end

      Timecop.freeze(transaction_time + 2.hours) do
        Transaction.create!(:donation => @donation, :successful => true)
        Transaction.create!(:donation => @donation, :successful => false)
      end

      Transaction.create!(:donation => @donation, :successful => true)
      @user.transaction_history(from: Date.parse('26-04-2013'), to: Date.parse('26-04-2013')).size.should eql 3
    end
  end

  describe 'enrolled_for_quick_donate?' do
    it "is false if user has no trigger" do
      user = build(:user, quick_donate_trigger_id: '')
      user.should_not be_enrolled_for_quick_donate
    end
    it "is true if user has no trigger" do
      user = build(:user, quick_donate_trigger_id: 'SOME')
      user.should be_enrolled_for_quick_donate
    end
  end

  describe 'find_quick_donate' do
    it "return nil if quick donate has not been triggered" do
      user = build(:user, quick_donate_trigger_id: '')
      donation = create(:donation, :card_number => PaymentGateways::CARD_SUCCESS, :frequency => "one-off", :user => user)
      Transaction.create!(:donation => donation, :successful => true)
      user_donation = user.find_quick_donation
      user_donation.should be nil
    end
    it 'return donation of person who has quick donate trigger id'do
      quick_donate_trigger_id = 'SOME'
      user = build(:user, quick_donate_trigger_id: quick_donate_trigger_id)
      donation = create(:donation, :card_number => PaymentGateways::CARD_SUCCESS, :frequency => "one-off", :user => user, trigger_id: quick_donate_trigger_id)
      Transaction.create!(:donation => donation, :successful => true)
      user_donation = user.find_quick_donation
      user_donation.should_not be nil
      user_donation.should eql donation
    end
    it "return nil if user's quick donate trigger id does not match donation's one" do
      quick_donate_trigger_id = 'SOME'
      another_trigger_id = 'ANOTHER'
      user = build(:user, quick_donate_trigger_id: quick_donate_trigger_id)
      donation = create(:donation, :card_number => PaymentGateways::CARD_SUCCESS, :frequency => "one-off", :user => user, trigger_id: another_trigger_id)
      Transaction.create!(:donation => donation, :successful => true)
      user_donation = user.find_quick_donation
      user_donation.should be nil
    end
  end

  describe "needs_more_details_for_page" do

    let :required_user_details do
      {
          :first_name => :required,
          :last_name => :required,
          :postcode_number => :optional,
          :mobile_number => :optional,
          :home_number => :hidden,
          :street_address => :hidden,
          :suburb => :hidden,
          :country_iso => :hidden,
      }
    end

    let :page do
      create(:page_with_parent, required_user_details: required_user_details)
    end

    it "should return false if all required and optional attributes present" do
      user = build(:user, first_name: 'First', last_name: 'Last', postcode: create(:postcode, number: '2222'), mobile_number: '0456 789012')
      user.needs_more_details_for_page(page).should be false
    end

    it "should return true if any required attributes not present" do
      user = build(:user, first_name: '', last_name: 'Last', postcode: create(:postcode, number: '2222'), mobile_number: '0456 789012')
      user.needs_more_details_for_page(page).should be true
    end

    it "should return true if any optional attributes not present" do
      user = build(:user, first_name: 'First', last_name: 'Last', postcode: nil, mobile_number: '0456 789012')
      user.needs_more_details_for_page(page).should be true
    end

    it "should return true if any refresh attributes present" do
      required_user_details[:first_name] = :refresh
      user = build(:user, first_name: 'First', last_name: 'Last', postcode: create(:postcode, number: '2222'), mobile_number: '0456 789012')
      user.needs_more_details_for_page(page).should be true
    end
  end

  describe "clear_attributes" do
    it "should clear specified attributes without saving" do
      user = build(:user, first_name: 'First', last_name: 'Last', postcode: nil, mobile_number: '0456 789012')
      user.clear_attributes([:first_name, 'last_name'])
      user.first_name.should be_blank
      user.last_name.should be_blank
      user.should_not be_persisted
    end
  end

  describe 'address validated at' do
    before(:each) do
      create(:postcode, number: '2010')
    end
    let(:user) { create(:user, email: 'user@domain.com.au') }

    it 'should update address validated at when supplied' do
      user.street_address = 'Unit 201 104 Commonwealth St'
      user.postcode_number = '2010'
      address_validated_time = Time.local(2013, 10, 10, 10, 0, 0)
      user.address_validated_at = address_validated_time
      user.save!

      user.reload
      user.address_validated_at.should == address_validated_time

      user.street_address = '9 Reservoir St'
      new_address_time = Time.local(2013, 11, 10, 10, 0, 0)
      user.address_validated_at = new_address_time
      user.save!

      user.reload
      user.address_validated_at.should == new_address_time
    end

    it 'should leave address_validated_at clear when address_validated_at not supplied' do
      user.street_address = '30 George St'
      user.street_address = 'Unit 201 104 Commonwealth St'
      user.postcode_number = '2010'
      user.first_name = 'bob'
      user.save!

      user.reload
      user.address_validated_at.should be_nil
    end

    context 'should clear address validated at when address field changed' do
      before(:each) do
        user.street_address = '30 George St'
        user.street_address = 'Unit 201 104 Commonwealth St'
        user.postcode_number = '2010'
        address_validated_at_time = Time.local(2013, 10, 10, 10, 0, 0)
        user.address_validated_at = address_validated_at_time
        user.save!
      end

      it 'should reset address_validated_at only when address updated and address_validated_at not supplied' do
        user.address_validated_at.should_not be_nil

        user.first_name = 'Jimmy'
        user.save!
        user.reload
        user.address_validated_at.should_not be_nil

        user.street_address = '55 Marrickville Rd'
        user.suburb = 'Marrickville'
        user.postcode_number = '2204'
        user.save!
        user.reload
        user.address_validated_at.should be_nil
      end
    end
  end

  context "with add_subscribed_members_to_dark_filter_experiments set" do

    before do
      Rails.configuration.stub(:add_subscribed_members_to_dark_filter_experiments).and_return(true)
    end

    describe "a subscribing user" do

      let(:user) { create(:user, is_member: false) }

      it "should consider the user for a dark filter experiment" do
        delayed_mock = double(:delay)
        delayed_mock.should_receive(:consider_for_experiment).with(user, {})
        DarkFilter::DarkFilter.should_receive(:delay).and_return(delayed_mock)
        user.is_member = true
        user.save!
      end
    end

    describe "a subscribing user from community run" do

      let(:user) { create(:user, is_member: false) }

      it "should consider the user for a dark filter experiment with the community run categories" do
        delayed_mock = double(:delay)
        delayed_mock.should_receive(:consider_for_experiment).with(user, {source: 'cr', community_run_categories: ['test', 'environment']})
        DarkFilter::DarkFilter.should_receive(:delay).and_return(delayed_mock)
        user.is_member = true
        user.save_with_source_info! nil, nil, nil, 'cr', nil, community_run_categories: ['test', 'environment']
      end
    end
  end

  describe "'privileged' scope" do
    before do
      User.create! email: "user@getup.org.au"
      User.create! email: "volunteer@getup.org.au", is_volunteer: true
      User.create! email: "admin@getup.org.au", is_admin: true
    end

    subject { User.privileged }
    let(:user)      { User.find_by_email("user@getup.org.au") }
    let(:volunteer) { User.find_by_email("volunteer@getup.org.au") }
    let(:admin)     { User.find_by_email("admin@getup.org.au") }

    it "does not return normal users" do
      subject.should_not include(user)
    end

    it "returns all 'privileged' users (currently admins & volunteers)" do
      subject.should include(volunteer, admin)
    end
  end
  
  describe "#generate_user_segment" do
    it "should generate appropriate segments number based on segment size and biggest user's id" do
      User.generate_users_segment(10, 102).should == [
        [1,10],
        [11,20],
        [21,30],
        [31,40],
        [41,50],
        [51,60],
        [61,70],
        [71,80],
        [81,90],
        [91,100],
        [101,102]
      ]
    end
    it "last segment should end with biggest user's id" do
      User.generate_users_segment(100, 99).should == [
        [1, 99]
      ]
    end
  end

  describe ".not_in_nationbuilder" do
    it "excludes users that have previously synced to nationbuilder" do
      user = create :user
      nb_user = create :user, nation_builder_user: create(:nation_builder_user, nationbuilder_id: 1)
      User.not_in_nationbuilder([user.id, nb_user.id]).should == [user]
    end
  end

  it "#emails_received_from_trigger_service should return all emails that have been sent to user by trigger service" do
    user = User.create email: "user@user.com"
    SentTriggerEmail.create user_id: user.id, key: "donation_failing_follow_up_email", sent_date: "24-03-2015"
    SentTriggerEmail.create user_id: user.id, key: "cancellation_warning_email", sent_date: "24-04-2015"
    SentTriggerEmail.create user_id: user.id, key: "donation_failing_follow_up_email", sent_date: "24-05-2015"
    user.emails_received_from_trigger_service.size.should == 3
    user.emails_received_from_trigger_service.first.sent_date.to_date.strftime("%d-%m-%Y").should == "24-05-2015"
  end

  describe "#quarantine!" do
    let(:user){ create(:user) }
    let(:page){ create(:page_with_parent) }
    let(:email){ create(:email) }
    let(:source){ 'test' }
    let(:agra_action){ create(:agra_action_signer) }

    it "should create a quarantine record" do
      user.quarantine!
      expect(user).to be_quarantined
      expect(user.quarantine).to be_present
    end

    it "should create a user activity event" do
      user.quarantine!(source: source, page: page, email: email, agra_action: agra_action)
      quarantine_events = user.user_activity_events.quarantines
      expect(quarantine_events.count).to eq(1)
      expect(quarantine_events.first.email).to eq(email)
      expect(quarantine_events.first.page).to eq(page)
      expect(quarantine_events.first.source).to eq(source)
      expect(quarantine_events.first.user_response).to eq(agra_action)
      expect(user.quarantine.user_activity_event).to eq(quarantine_events.first)
    end
  end

  describe "#unquarantine!" do
    let(:user){ create(:user) }
    before{ user.quarantine! }

    it "should remove the quarantine record" do
      user.unquarantine!
      expect(user).to_not be_quarantined
      expect(user.quarantine).to_not be_present
    end

    it "should create a user activity event" do
      user.unquarantine!(source: 'test')
      unquarantine_events = user.user_activity_events.unquarantines
      expect(unquarantine_events.count).to eq(1)
      expect(unquarantine_events.first.source).to eq('test')
      expect(unquarantine_events.first.user_response).to eq(user.user_activity_events.quarantines.last)
    end
  end
end
