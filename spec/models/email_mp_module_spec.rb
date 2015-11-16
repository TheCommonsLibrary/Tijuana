require File.dirname(__FILE__) + '/../spec_helper.rb'

describe EmailMPModule do
  it_behaves_like "an email module"
  it_behaves_like "a talking point module"
  it_behaves_like "a target representative finder"

  def validated_email_mp_module(attrs = {})
    etm = create(:email_mp_module)
    etm.update_attributes attrs
    etm.valid?
    etm
  end

  describe "validation" do
    it "should require a title between 3 and 128 characters" do
      validated_email_mp_module(:title => "Save the kittens!").should be_valid
      validated_email_mp_module(:title => "X" * 128).should be_valid
      validated_email_mp_module(:title => "X" * 129).should_not be_valid
      validated_email_mp_module(:title => "AB").should_not be_valid
    end

    it "should require a button text between 1 and 64 characters" do
      validated_email_mp_module(:button_text => "Save the kittens!").should be_valid
      validated_email_mp_module(:button_text => "X" * 64).should be_valid
      validated_email_mp_module(:button_text => "X" * 65).should_not be_valid
      validated_email_mp_module(:button_text => "").should_not be_valid
    end

    it "should require a default subject between 2 and 256 characters" do
      validated_email_mp_module(:default_subject => "Save the kittens!").should be_valid
      validated_email_mp_module(:default_subject => "X" * 255).should be_valid
      validated_email_mp_module(:default_subject => "X" * 256).should_not be_valid
      validated_email_mp_module(:default_subject => "").should_not be_valid
    end

    context "when a jurisdiction with target parties is selected" do
      let!(:jurisdiction) { create(:federal_jurisdiction_with_parties) }

      it "should require at least one target party to be selected" do
        validated_email_mp_module(:target_party_ids => {1 => '1'}).should be_valid
        validated_email_mp_module(:target_party_ids => {}).should_not be_valid
      end
    end
  end

  describe "defaults" do
    it "should set appropriate defaults" do
      page = create(:page_with_parent)
      etm = EmailMPModule.create!(:title => "A Title", :default_subject => "The Subject", :default_body => "The body which needs to be over 10 chars.")
      ContentModuleLink.create!(:page => page, :content_module => etm)
      etm.button_text.should eql('Send!')
      etm.prompt_as_default?.should == true
      etm.cc_me.should == false
      etm.target_party_ids.should be_empty
      etm.target_senate.should be true
    end
  end

  describe '#show_steps?' do
    it 'should return true' do
      subject.show_steps = '1'
      subject.show_steps?.should be true
    end

    it 'should return false' do
      subject.show_steps = '0'
      subject.show_steps?.should be false
    end
  end

  describe "taking an action" do
    before do
      ActionMailer::Base.deliveries = []
      UserMailer.stub(:welcome_to_getup_email) { double(:deliver => nil) }
      @page = create(:page_with_parent)
    end

    it 'should create a user activity event' do
      user = create(:user, :email => 'noone@example.com')
      ask = create(:email_mp_module)

      UserActivityEvent.should_receive(:action_taken!).with(user, @page, ask, an_instance_of(UserEmail), nil, nil, nil)

      ask.update_action_attributes_and_validate(:user_email => {:subject => "1234", :body => "abcd"}, :targets => "moo@homes.com")
      ask.take_action(user, @page)
    end

    it "should raise an error if the ask/user combo has been seen before" do
      user = create(:user, :email => 'noone@example.com')
      ask = create(:email_mp_module)

      ask.update_action_attributes_and_validate(:user_email => {:subject => "1234", :body => "abcd"}, :targets => "moo@homes.com")
      ask.take_action(user, @page)
      expect { ask.take_action(user, @page) }.to raise_error(DuplicateActionTakenError)
    end

    describe "should record what was sent as part of taking the action" do
      it "when sent to mp is delayed" do
        user = create(:user, :email => 'noone@example.com')
        ask = create(:email_mp_module, :cc_me => true, :delayed_end_date => 7.days.from_now)

        ask.update_action_attributes_and_validate(:user_email => {:subject => "1234", :body => "abcd", :cc_me => "0"}, :targets => "moo@homes.com")
        ask.take_action(user, @page)

        user_email = UserEmail.first
        user_email.subject.should == "1234"
        user_email.body.should include("abcd")
        user_email.targets.should == "moo@homes.com"
        user_email.cc_me.should be false
      end

      it "when sent to mp is not delayed" do
        user = create(:user, :email => 'noone@example.com')
        ask = create(:email_mp_module, :cc_me => true, :delayed_end_date => "")

        ask.update_action_attributes_and_validate(:user_email => {:subject => "1234", :body => "abcd", :cc_me => "0"}, :targets => "moo@homes.com")
        ask.take_action(user, @page)

        user_email = UserEmail.first
        user_email.subject.should == "1234"
        user_email.body.should include("abcd")
        user_email.targets.should == "moo@homes.com"
        user_email.cc_me.should be false
      end

      it "and the cc_me" do
        user = create(:user, :email => 'noone@example.com')
        ask = create(:email_mp_module, :cc_me => true, :delayed_end_date => "")

        ask.update_action_attributes_and_validate(:user_email => {:subject => "1234", :body => "abcd", :cc_me => "1"}, :targets => "moo@homes.com")
        ask.take_action(user, @page)

        user_email = UserEmail.first
        user_email.subject.should == "1234"
        user_email.body.should include("abcd")
        user_email.targets.should == "moo@homes.com"
        user_email.cc_me.should be true
      end
    end


    describe "handle the copy to member request as part of taking the action" do

      it "by sending it if requested" do
        user = create(:user, :email => 'noone@example.com', :is_member => "true")
        ask = create(:email_mp_module, :delayed_end_date => "")

        ask.update_action_attributes_and_validate(:user_email => {:subject => "1234", :body => "abcd", :cc_me => "1"}, :targets => "moo@homes.com")
        ask.take_action(user, @page)
        Delayed::Worker.new.work_off
        ActionMailer::Base.deliveries.count.should == 2
        delivery_to_target = ActionMailer::Base.deliveries.find { |d| d[:To].to_s == "moo@homes.com" }
        delivery_to_self = ActionMailer::Base.deliveries.find { |d| d[:To].to_s == "noone@example.com" }
        delivery_to_target.should_not be_nil
        delivery_to_self.should_not be_nil
      end

      it "by not sending it if not requested" do

        user = create(:user, :email => 'noone@example.com', :is_member => "true")
        ask = create(:email_mp_module, :delayed_end_date => "")

        ask.update_action_attributes_and_validate(:user_email => {:subject => "1234", :body => "abcd", :cc_me => "0"}, :targets => "moo@homes.com")
        ask.take_action(user, @page)
        Delayed::Worker.new.work_off
        ActionMailer::Base.deliveries.count.should == 1
        delivery_to_target = ActionMailer::Base.deliveries.find { |d| d[:To].to_s == "moo@homes.com" }
        delivery_to_self = ActionMailer::Base.deliveries.find { |d| d[:To].to_s == "noone@example.com" }
        delivery_to_target.should_not be_nil
        delivery_to_self.should be_nil
      end
    end

    it "should delay the send to the date randomly set" do
      user = create(:user, :email => 'noone@example.com', :is_member => "true")
      emp = create(:email_mp_module, :delayed_end_date => 50.days.from_now)
      emp.update_action_attributes_and_validate(:user_email => {:subject => "1234", :body => "abcd", :cc_me => false}, :targets => "moo@homes.com")
      twenty_days_from_now = 20.days.from_now
      emp.user_email.stub(:when_to_run).and_return(twenty_days_from_now)
      emp.take_action(user, @page)
      Delayed::Job.count.should >= 1
      Delayed::Job.last.run_at.to_s.should == twenty_days_from_now.to_s
    end

    it "should postpone the email to mp to a later date as part of taking the action" do
      user = create(:user, :email => 'noone@example.com')
      ask = create(:email_mp_module, :cc_me => true, :delayed_end_date => 4.days.from_now)

      # Prevent from creating delayed job
      MemberValue.stub(:queue_recalculate_for_user)

      ask.update_action_attributes_and_validate(:user_email => {:subject => "1234", :body => "abcd", :cc_me => nil}, :targets => "moo@homes.com")
      Delayed::Job.count.should >= 0
      count = Delayed::Job.count

      mocked_days_from_today_to_schedule = 1
      Kernel.stub(:rand).with(4).and_return(mocked_days_from_today_to_schedule)
      ask.take_action(user, @page)
      # Delayed::Worker.new.work_off
      Delayed::Job.count.should == count + 1
      expect(Delayed::Job.last.run_at.to_date).to eq(Date.today + mocked_days_from_today_to_schedule)
      Delayed::Job.last.run_at.to_date.should <= ask.delayed_end_date.to_date
    end

    it "should send the default body if one is not entered" do
      user = create(:user, :email => 'noone@example.com')
      ask = create(:email_mp_module, :default_body => "DEfault Body")

      ask.update_action_attributes_and_validate(:user_email => {:subject => "", :body => ""}, :targets => "moo@homes.com")
      ask.take_action(user, @page)

      user_email = UserEmail.first
      user_email.body.should include("DEfault Body")
    end

    it "should send the default subject if one is not entered" do
      user = create(:user, :email => 'noone@example.com')
      ask = create(:email_mp_module, :default_subject => "DEfault Subjerct")

      ask.update_action_attributes_and_validate(:user_email => {:subject => "", :body => ""}, :targets => "moo@homes.com")
      ask.take_action(user, @page)

      user_email = UserEmail.first
      user_email.subject.should == "DEfault Subjerct"
    end
  end

  describe "target parties" do
    it "should accept a hash for the selected parties and return an array" do
      page = create(:page_with_parent)
      etm = EmailMPModule.create
      etm.target_party_ids = {"1" => "1", "2" => "0", "3" => "1", "4" => "1", "5" => "0"}
      etm.target_party_ids.should == [1, 3, 4]
    end
  end

  describe "#jurisdiction" do
    before do
      Jurisdiction.create!(:name => "Federal", :code => "FEDERAL")
      Jurisdiction.create!(:name => "New South Wales", :code => "NSW")
    end

    it "should retrieve module jurisdiction when content module jurisdiction is not present" do
      empty_content_module = create(:email_mp_module)
      empty_content_module.jurisdiction.code.should eql "FEDERAL"
    end

    it "should retrieve module jurisdiction when content module jurisdiction code is NSW" do
      nsw_content_module = create(:email_mp_module)
      nsw_content_module.jurisdiction_code = "NSW"
      nsw_content_module.jurisdiction.code.should eql "NSW"
    end

  end

end
