require File.dirname(__FILE__) + '/../spec_helper.rb'

describe EmailTargetsModule do
  it_behaves_like "an email module"
  it_behaves_like "a talking point module"

  def validated_email_targets_module(attrs)
    etm = create(:email_targets_module)
    etm.update_attributes attrs
    etm.valid?
    etm
  end
  
  describe "validation" do
    it "should require a title between 3 and 128 characters" do
      validated_email_targets_module(:title => "Save the kittens!").should be_valid
      validated_email_targets_module(:title => "X" * 128).should be_valid
      validated_email_targets_module(:title => "X" * 129).should_not be_valid
      validated_email_targets_module(:title => "AB").should_not be_valid
    end

    it "should require a button text between 1 and 64 characters" do
      validated_email_targets_module(:button_text => "Save the kittens!").should be_valid
      validated_email_targets_module(:button_text => "X" * 64).should be_valid
      validated_email_targets_module(:button_text => "X" * 65).should_not be_valid
      validated_email_targets_module(:button_text => "").should_not be_valid
    end

    it "should create a default button text" do
      #NB we can't use the factory for this cherry
      page = create(:page_with_parent)
      etm = EmailTargetsModule.create
      etm.button_text.should eql('Send!')
    end
    
    it "should require a default subject between 2 and 255 characters" do
      validated_email_targets_module(:default_subject => "Save the kittens!").should be_valid
      validated_email_targets_module(:default_subject => "X" * 255).should be_valid
      validated_email_targets_module(:default_subject => "X" * 256).should_not be_valid
      validated_email_targets_module(:default_subject => "").should_not be_valid
    end
    
    it "should require only valid email addresses, with a minimum of 1" do
      validated_email_targets_module(:target_emails => "user1@getup.org.au").should be_valid
      validated_email_targets_module(:target_emails => "user1@getup.org.au, user2@getup").should_not be_valid
      validated_email_targets_module(:target_emails => "user1@getup.org.au" * 257).should_not be_valid
      validated_email_targets_module(:target_emails => "").should_not be_valid
    end
    
    it "should allow email addresses delimited by commas" do
      validated_email_targets_module(:target_emails => "user1@getup.org.au, user2@getup.com").should be_valid
    end
    
    it "should allow email addresses delimited by spaces" do
      validated_email_targets_module(:target_emails => "user1@getup.org.au user2@getup.com").should be_valid
    end
    
    it "should allow email addresses delimited by semi-colons" do
      validated_email_targets_module(:target_emails => "user1@getup.org.au; user2@getup.com").should be_valid
    end
  end
  
  describe "taking an action" do
    before do
      ActionMailer::Base.deliveries = []
      UserMailer.stub(:welcome_to_getup_email) { double(:deliver=>nil) }
      @page = create(:page_with_parent)
    end

    it 'should create a user activity event' do
      user = create(:user, :email => 'noone@example.com')
      ask = create(:email_targets_module)

      UserActivityEvent.should_receive(:action_taken!).with(user, @page, ask, an_instance_of(UserEmail), nil, nil, nil)

      ask.update_action_attributes_and_validate(:user_email => {:subject => "1234", :body => "abcd"})
      ask.take_action(user, @page)
    end
    
    it "should raise an error if the ask/user combo has been seen before" do
      user = create(:user, :email => 'noone@example.com')
      ask = create(:email_targets_module)
      ask.take_action(user, @page)
      expect { ask.take_action(user, @page) }.to raise_error(DuplicateActionTakenError)
    end
    
    
    describe "should record what was sent as part of taking the action" do
      it "when sent to targets is delayed" do
        user = create(:user, :email => 'noone@example.com')
        ask = create(:email_targets_module, :target_emails => "bob@gomez.com, enrico@sanchez.com", :delayed_end_date => 100.days.from_now)
    
        ask.update_action_attributes_and_validate(:user_email => {:subject => "1234", :body => "abcd", :cc_me => "0"})
        ask.take_action(user, @page)
    
        user_email = UserEmail.first
        user_email.subject.should == "1234"
        user_email.body.should include("abcd")
        user_email.targets.should == "bob@gomez.com, enrico@sanchez.com"
        user_email.cc_me.should be false
      end

      it "when sent to targets is not delayed" do
        user = create(:user, :email => 'noone@example.com')
        ask = create(:email_targets_module, :target_emails => "bob@gomez.com, enrico@sanchez.com", :delayed_end_date => "")
    
        ask.update_action_attributes_and_validate(:user_email => {:subject => "1234", :body => "abcd", :cc_me => "0"})
        ask.take_action(user, @page)
    
        user_email = UserEmail.first
        user_email.subject.should == "1234"
        user_email.body.should include("abcd")
        user_email.targets.should == "bob@gomez.com, enrico@sanchez.com"
        user_email.cc_me.should be false
      end

      it "and the cc_me" do
        user = create(:user, :email => 'noone@example.com')
        ask = create(:email_targets_module, :target_emails => "bob@gomez.com, enrico@sanchez.com", :delayed_end_date => "")
    
        ask.update_action_attributes_and_validate(:user_email => {:subject => "1234", :body => "abcd", :cc_me => "1"})
        ask.take_action(user, @page)
    
        user_email = UserEmail.first
        user_email.subject.should == "1234"
        user_email.body.should include("abcd")
        user_email.targets.should == "bob@gomez.com, enrico@sanchez.com"
        user_email.cc_me.should be true
      end
    end
    
    describe "handle the copy to member request as part of taking the action" do
  
      it "by sending it if requested" do
        user = create(:user, :email => 'noone@example.com', :is_member => "true")
        ask = create(:email_targets_module, :target_emails => "bob@gomez.com, enrico@sanchez.com", :delayed_end_date => "")
    
        ask.update_action_attributes_and_validate(:user_email => {:subject => "1234", :body => "abcd", :cc_me => "1"})
        ask.take_action(user, @page)
        Delayed::Worker.new.work_off
        ActionMailer::Base.deliveries.count.should == 2
        delivery_to_target = ActionMailer::Base.deliveries.find {|d| d[:To].to_s == "bob@gomez.com, enrico@sanchez.com"}
        delivery_to_self = ActionMailer::Base.deliveries.find {|d| d[:To].to_s == "noone@example.com"}
        delivery_to_target.should_not be_nil
        delivery_to_self.should_not be_nil
      end

      it "by not sending it if not requested" do
        
        user = create(:user, :email => 'noone@example.com', :is_member => "true")
        ask = create(:email_targets_module, :target_emails => "bob@gomez.com, enrico@sanchez.com", :delayed_end_date => "")
    
        ask.update_action_attributes_and_validate(:user_email => {:subject => "1234", :body => "abcd", :cc_me => "0"})
        ask.take_action(user, @page)
        Delayed::Worker.new.work_off
        ActionMailer::Base.deliveries.count.should == 1
        delivery_to_target = ActionMailer::Base.deliveries.find {|d| d[:To].to_s == "bob@gomez.com, enrico@sanchez.com"}
        delivery_to_self = ActionMailer::Base.deliveries.find {|d| d[:To].to_s == "noone@example.com"}
        delivery_to_target.should_not be_nil
        delivery_to_self.should be_nil
      end
    end
    
    it "should delay the send to the date randomly set" do
      user = create(:user, :email => 'noone@example.com', :is_member => "true")
      et = create(:email_targets_module, :target_emails => "bob@gomez.com, enrico@sanchez.com", :delayed_end_date => 50.days.from_now)
      et.update_action_attributes_and_validate(:user_email => {:subject => "1234", :body => "abcd", :cc_me => false})
      twenty_days_from_now = 20.days.from_now
      et.user_email.stub(:when_to_run).and_return(twenty_days_from_now)
      et.take_action(user, @page)
      Delayed::Job.count.should >= 1
      Delayed::Job.last.run_at.to_s.should == twenty_days_from_now.to_s
    end

    it "should postpone the email to targets to a later date as part of taking the action" do
      user = create(:user, :email => 'noone@example.com')
      ask = create(:email_targets_module, :target_emails => "bob@gomez.com, enrico@sanchez.com", :delayed_end_date => 4.days.from_now)

      # Prevent from creating delayed job
      MemberValue.stub(:queue_recalculate_for_user)

      ask.update_action_attributes_and_validate(:user_email => {:subject => "1234", :body => "abcd", :cc_me => nil})
      Delayed::Job.count.should >= 0
      count = Delayed::Job.count

      ask.take_action(user, @page)
      # Delayed::Worker.new.work_off
      Delayed::Job.count.should == count + 1
      Delayed::Job.last.run_at.should > Date.yesterday
      Delayed::Job.last.run_at.should <= ask.delayed_end_date
    end
    
    it "should send the default body if one is not entered" do
      user = create(:user, :email => 'noone@example.com')
      ask = create(:email_targets_module, :target_emails => "bob@gomez.com, enrico@sanchez.com", :default_body => "DEfault Body")
      ask.take_action(user, @page)     
      
      user_email = UserEmail.first 
      user_email.body.should match("DEfault Body")
    end
    
    it "should send the default subject if one is not entered" do
      user = create(:user, :email => 'noone@example.com')
      ask = create(:email_targets_module, :target_emails => "bob@gomez.com, enrico@sanchez.com", :default_subject => "DEfault Subjerct")
      ask.take_action(user, @page)  
      
      user_email = UserEmail.first    
      user_email.subject.should == "DEfault Subjerct"
    end
    
    it "should append all required fields to the email body" do
      user = create(:user, :first_name => "Franck", :last_name => "Hicks", :email => 'noone@example.com', :postcode => create(:postcode_of_circular_quay), :street_address => "4/12 Bondi road")
      ask = create(:email_targets_module, :target_emails => "bob@gomez.com, enrico@sanchez.com", :default_body => "DEfault Body")
      @page.required_user_details[:postcode_number] = :required
      @page.required_user_details[:street_address] = :optional
      @page.save!
      ask.take_action(user, @page)     
      
      user_email = UserEmail.first 
      user_email.body.should match("Franck")
      user_email.body.should match("Hicks")
      user_email.body.should match('noone@example.com')
      user_email.body.should match('2000')
      user_email.body.should match("DEfault Body")
      user_email.body.should_not match('4/12 Bondi road')
    end
  end

  describe "setting default email text" do
    it "should handle legacy 'display defaults' options" do
      ask = create(:email_targets_module, :target_emails => "bob@gomez.com", :default_subject => "DEfault Subjerct", :default_body => 'body default here', 
                           :email_prompt_as => nil, :display_defaults => '1')
      ask.prompt_as_placeholder?.should be false
      ask.prompt_as_default?.should be true

      ask.display_defaults = '0'
      ask.prompt_as_placeholder?.should be false
      ask.prompt_as_default?.should be false
    end

    it "should handle no email_prompt_as" do
      ask = create(:email_targets_module, :target_emails => "bob@gomez.com", :default_subject => "DEfault Subjerct", :default_body => 'default body text', 
                           :email_prompt_as => nil, :display_defaults => nil)
      ask.prompt_as_placeholder?.should be false
      ask.prompt_as_default?.should be false
    end
  end
end
