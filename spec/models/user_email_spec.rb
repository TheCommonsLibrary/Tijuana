require File.dirname(__FILE__) + '/../spec_helper.rb'

describe UserEmail do  
  def assert_email_sent(args)
    assert_email_sending(true, args)
  end

  def assert_email_not_sent(args)
    assert_email_sending(false, args)
  end
   
  def assert_email_sending(should_send, args)
    job_double = double
    arg_keys = [:targets, :from, :cc, :subject, :body]
    if args[:tracking_token]
      arg_keys << :tracking_token
    end
    if(should_send)
      Emailer.should_receive(:delay) { job_double }
      job_double.should_receive(:target_email).with(*arg_keys.map{|arg| args[arg] })
    else
      job_double.should_not_receive(:target_email).with(*arg_keys.map{|arg| args[arg] })
    end
  end

  before do
    @user = create(:user, :email => 'noone@example.com')
    @cm = create(:email_targets_module)
    @page = create(:page_with_parent)
  end

  describe "validation" do
    it "requires all its fields to be valid" do
      UserEmail.new(:content_module => @cm, :page => @page, :user => @user, :subject => "Subject", 
          :body => "Body", :targets => "mrbob@escobar.com").should be_valid
      UserEmail.new(:content_module => @cm, :page => @page, :user => @user, :body => "Body", 
          :targets => "mrbob@escobar.com").should_not be_valid
      UserEmail.new(:content_module => @cm, :page => @page, :user => @user, :subject => "Subject", 
          :targets => "mrbob@escobar.com").should_not be_valid
    end

    it 'does not allow a subject having more than 255 characters' do
      UserEmail.new(:content_module => @cm, :page => @page, :user => @user, :subject => "1" * 255, 
          :body => "Body", :targets => "mrbob@escobar.com").should be_valid
      UserEmail.new(:content_module => @cm, :page => @page, :user => @user, :subject => "1" * 256, 
          :body => "Body", :targets => "mrbob@escobar.com").should_not be_valid
    end

    context "no target set" do
      context "target list module" do
        it "should record error on target list" do
          user_email = UserEmail.new(:content_module => @cm, :page => @page, :user => @user, 
              :subject => "Subject", :body => "Body", :targets => "")
          user_email.for_target_list_module = true
          user_email.email_target_is_selected
          user_email.errors.size.should eql 1
          user_email.errors[:list_target].should_not be_empty
        end
      end

      context "not target list module" do
        it "should record base error" do
          user_email = UserEmail.new(:content_module => @cm, :page => @page, :user => @user, 
              :subject => "Subject", :body => "Body", :targets => "")
          user_email.for_target_list_module = false
          user_email.email_target_is_selected
          user_email.errors.size.should eql 1
          user_email.errors[:base].should_not be_empty
        end
      end
    end
  end

  describe "emails" do
    let(:tracking_token){ 'XXXX' }
    let(:hashids_library){ double }

    it "creates a sensible email" do
      user_email = UserEmail.create!(:user => @user, :subject => "Booyah", 
          :body => "Put down the stapler Milton", :targets => "bob@bobson.com, mrsanchez@gomez.com", 
          page: create(:page_with_parent),
          :cc_me => false, :content_module => @cm)
      EmailTargetTrackingLog.should_receive(:generate_token).with(user_email).and_return(tracking_token)
      assert_email_sent(:targets => "bob@bobson.com, mrsanchez@gomez.com", :from => "noone@example.com", 
          :cc => nil, :subject => "Booyah", :body => "Put down the stapler Milton", tracking_token: tracking_token)
      user_email.send!
    end

    it "CC's the user if they request it" do
      user_email = UserEmail.create!(:user => @user, :subject => "Booyah", 
          :body => "Put down the stapler Milton", :targets => "bob@bobson.com, mrsanchez@gomez.com", 
          page: create(:page_with_parent),
          :cc_me => '1', :content_module => @cm)
      assert_email_sent(:targets => "noone@example.com", :from => "noone@example.com", :cc => nil, 
          :subject => "Booyah", :body => "Put down the stapler Milton")
      EmailTargetTrackingLog.should_receive(:generate_token).with(user_email).and_return(tracking_token)
      assert_email_sent(:targets => "bob@bobson.com, mrsanchez@gomez.com", :from => "noone@example.com", 
          :cc => nil, :subject => "Booyah", :body => "Put down the stapler Milton", tracking_token: tracking_token)
      user_email.send!
    end

    it "not send email to target if 'send to target' is not set" do
      user_email = UserEmail.create!(:user => @user, :subject => "Booyah", 
          :body => "Put down the stapler Milton", :targets => "bob@bobson.com, mrsanchez@gomez.com", 
          page: create(:page_with_parent),
          :cc_me => '1', :content_module => @cm,
          :send_to_target => false)
      assert_email_sent(:targets => "noone@example.com", :from => "noone@example.com", :cc => nil, 
          :subject => "Booyah", :body => "Put down the stapler Milton")
      EmailTargetTrackingLog.should_receive(:generate_token).with(user_email).and_return(tracking_token)
      assert_email_not_sent(:targets => "bob@bobson.com, mrsanchez@gomez.com", :from => "noone@example.com", 
          :cc => nil, :subject => "Booyah", :body => "Put down the stapler Milton", tracking_token: tracking_token)
      user_email.send!
    end
  end


  describe "#when_to_run" do
    context "content module has delayed end date" do
      let!(:content_module) {create(:email_mp_module, delayed_end_date: 30.days.from_now)}
      let(:user_email) {create(:user_email)}

      it "returns DateTime object in the local timezone" do
        expect(user_email.when_to_run(content_module.id)).to be_a_kind_of(DateTime)
        expect(user_email.when_to_run(content_module.id).zone).to eq(DateTime.now.zone)
      end

      xit "is in the future" do
        expect(user_email.when_to_run(content_module.id)).to be >= DateTime.now
      end

      it "returns distinct times" do
        expect(3.times.collect{ user_email.when_to_run(content_module.id) }.uniq.length).to be > 1
      end

      it "does not return times between midnight and five am" do
        expect((0..4).include?(user_email.when_to_run(content_module.id).hour)).to be false
        #try when we're requesting a time early in the morning
        Timecop.freeze(2011, 1, 2, 1, 0) do
          expect((0..4).include?(user_email.when_to_run(content_module.id).hour)).to be false
        end
      end

      xit 'randomises the minutes when the current time is out of the allowed hours' do
        Timecop.freeze(2011, 1, 2, 1, 0) do
          expect(3.times.collect{ user_email.when_to_run(content_module.id).minute }.uniq.length).to be > 1
        end
      end
    end

    context "in the past" do
      let!(:content_module) {create(:email_mp_module, delayed_end_date: 30.days.ago)}
      let(:user_email) {create(:user_email)}

      it "should send the email now" do
        expect(user_email.when_to_run(content_module.id).to_date).to eq(Date.today)
      end
    end
  end

end
