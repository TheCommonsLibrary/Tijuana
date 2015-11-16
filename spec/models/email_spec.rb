# encoding: utf-8

require File.expand_path(File.dirname(__FILE__) + "../../spec_helper")
require File.expand_path(File.dirname(__FILE__) + '/email_spec_helper')

describe Email do
  before(:each) do
    ActionMailer::Base.deliveries = []
  end

  def build_email(overrides={})
    email = create(:email)
    email.attributes = overrides
    email.save
    email
  end

  it 'substitutes normal quotes for smart quotes' do
    email = build_email(body: '“smart” double and ‘smart’ single quotes', subject: '“smart” double and ‘smart’ single quotes')
    email.subject.should == %Q{"smart" double and 'smart' single quotes}
    email.body.should == %Q{"smart" double and 'smart' single quotes}
  end
  
  it "creates sensible defaults for from and reply-to addresses" do
    Email.new.from_address.should == "info@getup.org.au"
    Email.new.reply_to_address.should == "contact@getup.org.au"
  end
  
  describe "validation" do
    it "requires all fields to be present" do
      build_email.should be_valid
      build_email(:blast => nil).should_not be_valid
      build_email(:name => "").should_not be_valid
      build_email(:from_address => "").should_not be_valid
      build_email(:from_name => "").should_not be_valid
      build_email(:reply_to_address => "").should_not be_valid
      build_email(:subject => "").should_not be_valid
      build_email(:body => "").should_not be_valid
    end
    
    it "validates format of email addresses" do
      build_email(:from_address => "not.real@").should_not be_valid 
      build_email(:reply_to_address => "lovely@spam").should_not be_valid 
    end

    it "does not change html" do
      email = create(:email, :body => "<ul><li>hi</li><li>bye</li></ul>")
      email.body.should ==  "<ul><li>hi</li><li>bye</li></ul>"
    end

    it "checks for naked links" do
      email = build(:email, :body => " This is a naked link: http://localhost")
      email.valid?
      email.should_not be_valid
    end

    it "checks for whitespace in link href attributes" do
      email = build(:email, :body => "<a href='http://www.google.com   '>afsdffs</a>")
      email.valid?
      email.should_not be_valid
    end

    it "should check get together id exists if present" do
      email = build(:email, get_together_id: 1)
      email.valid?
      email.errors.should have(1).error_on(:get_together_id)

      email = build(:email)
      email.valid?
      email.should be_valid

      get_together = create(:get_together)
      email = build(:email, get_together_id: get_together.id)
      email.valid?
      email.should be_valid
    end

    context "merge tokens" do
      it "should check for invalid tokens" do
        email = build(:email, body: '{MERGE:foo|your number}', subject: '{MERGE:bar|buddy}')
        email.valid?

        email.errors[:body].length.should == 1
        email.errors[:body][0].should match(/foo/)
        email.errors[:subject].length.should == 1
        email.errors[:subject][0].should match(/bar/)
      end

      it "should allow valid tokens" do
        Setting[:whitelist_merge_tokens] = 'blah'
        email = build(:email, body: '{MERGE:blah|your blah}', subject: '{MERGE:merge("hospitals", "name")|buddy}')

        email.valid?
      end
    end
  end

  describe "delivery" do
    it "should deliver a test email to the default test recipient and mark it as a sent test" do
      email = build_email(:body => "awesome", :subject=>"stuff")
      email_double = double()
      Emailer.stub(:blast) { email_double }
      Emailer.should_receive(:blast).with(email, :recipients => ['test@getup.org.au'], :test => true)
      email_double.should_receive(:deliver)

      email.test_sent_at.should be_nil
      email.send_test!
      Email.find(email.id).test_sent_at.should_not be_nil
    end

    it "should not mark as proofed, and email test recipient if proof throws exception" do
      User.create(:email=>'james@getup.org.au')
      ActionMailer::Base.deliveries = [] # reset as create user creates welcome email

      email = build_email(:body => "broken {CUSTOM_FRAGMENT|dontexist} yes", :subject=>"I am broken")

      email.send_test!(['james@getup.org.au'])
      email.reload
      email.test_sent_at.should be_nil

      ActionMailer::Base.deliveries.length.should == 2
      sent_email("PROOFING ERROR", "james@getup.org.au").should be true
      sent_email("ActionView::MissingTemplate", "tech-dev@getup.org.au").should be true
    end

    def sent_email(subject, to)
      ActionMailer::Base.deliveries.one? {|d| d.to.include?(to) && d.subject.include?(subject)} 
    end

    it "should deliver a test emails to the default test recipient and the provided email addresses" do
      email = build_email(:body => "awesome", :subject=>"stuff")
      email_double = double()
      Emailer.stub(:blast) {email_double}
      Emailer.should_receive(:blast).with(email, :recipients => ['another_recipient@gmail.com', 'test@getup.org.au'], :test => true)
      email_double.should_receive(:deliver)

      email.send_test!(['another_recipient@gmail.com'])
    end

    context "adding tracking hashes to links" do
      context "html body" do
        it "should pre-process the body for html" do
          email = build_email(:body => "Pls click <a href=\"http://somewhere.com\">here</a>")
          email.html_body.should == "Pls click <a href=\"http://somewhere.com?t={TRACKING_HASH|NOT_AVAILABLE}\">here</a>"
        end

        it "should not change links which are the default text for tokens" do
          email = build_email(:body => "{CLOSEST_EVENT|<a href=\"http://somewhere.com\">here</a>}")
          email.html_body.should == "{CLOSEST_EVENT|<a href=\"http://somewhere.com\">here</a>}"
        end

      end

      context "plain text" do
        it "should pre-process the body for plain text" do
          email = build_email(:body => "Pls click <a href=\"http://somewhere.com\">here</a>")
          email.plain_text_body.should == "Pls click here"
        end
      end
    end

    context "with secure hashes on links" do
      context "html body" do
        it "pre-process the body for html" do
          email = build_email(secure_links: true, body: "Pls click <a href=\"http://somewhere.com\">here</a>")
          email.html_body.should == "Pls click <a href=\"http://somewhere.com?t={TRACKING_HASH|NOT_AVAILABLE}&secure_token={SECURE_TOKEN|NOT_AVAILABLE}\">here</a>"
        end

        it "should not change links which are the default text for tokens" do
          email = build_email(body: "{CLOSEST_EVENT|<a href=\"http://somewhere.com\">here</a>}")
          email.html_body.should == "{CLOSEST_EVENT|<a href=\"http://somewhere.com\">here</a>}"
        end

      end

      context "plain text" do
        it "should pre-process the body for plain text" do
          skip "we shouldn't be stripping links out of html in this way"
          email = build_email(body: "Pls click <a href=\"http://somewhere.com\">here</a>")
          email.plain_text_body.should == "Pls click here"
        end
      end
    end

    it "should set test_sent_at when test is sent, and clear it when email field is saved" do
      email = create(:email, :body => "Pls click <a href=\"http://somewhere.com\">here</a>")
      email.test_sent_at.should be_nil
      
      email.send_test!(['dummy@email.com'])
      email.reload
      email.test_sent_at.should_not be_nil

      email.body = "something else here yes"
      email.save!
      email.test_sent_at.should be_nil

      email.update_column(:test_sent_at, Time.now)
      email.delayed_job_id = 1
      email.save!
      email.test_sent_at.should_not be_nil
    end

    it "should only clear test_sent_at on correct email" do
      email1 = create(:email, :body => "Pls click <a href=\"http://somewhere.com\">here</a>")
      email2 = create(:email, :body => "Hello hello 22222")
      
      email1.send_test!(['dummy@email.com'])
      email2.send_test!(['dummy@email.com'])
      email1.reload
      email2.reload

      email1.body = "something else"
      email1.save!

      email1.test_sent_at.should be_nil
      email2.test_sent_at.should_not be_nil
    end
  end

  describe "blast" do
    before(:each) do
      UserMailer.stub(:welcome_to_getup_email) { double(:deliver=>nil) }
    end
    
    it "should send a blast to all recipients in a given list up to the specified limit" do
      list = List.create
      list.set_country_rule(:country_iso => "AU")
      list.save

      users = create_users_with_descending_randomicity(['another_recipient@gmail.com', 'james@metallica.com', 'dave@megadeth.com', 'scott@anthrax.com', 'slash@slash.com'])
      push = create(:push)
      blast = create(:blast, push: push)
      email = build_email(:body => "Hello {NAME|Friend}! Pls click <a href=\"http://somewhere.com\">here</a>. Oh and you probably live near {POSTCODE|Nowhere}", :footer => "getup", :blast => blast)

      email.deliver_blast_in_batches([users[4],users[3],users[2]].map(&:id))

      ActionMailer::Base.deliveries.size.should eql(1)
      @delivered = ActionMailer::Base.deliveries.last
      header = JSON.parse(@delivered.header['X-SMTPAPI'].to_s)
      expect(["dave@megadeth.com", "scott@anthrax.com", "slash@slash.com"]).to match_array(header["to"])
    end

    without_transactional_fixtures do
      it "should batch up email delivery" do
        user1 = create(:user, :email=> 'leonardo@borges.com', :is_member => true)
        user2 = create(:user, :email=> 'another@dude.com', :is_member => true)
        email_to_send = create(:email_with_tokens, :footer => "getup")

        with_push_table(email_to_send.blast.push) do
          email_to_send.deliver_blast_in_batches([user1, user2].map(&:id), 1)

          email_to_send.blast.push.count_by_activity(:email_sent).should eql 2
          ActionMailer::Base.deliveries.size.should eql(2)
        end
      end
    end

    it "should log push issues" do
      user1 = create(:user, :email=> 'leonardo@borges.com', :is_member => true)
      user2 = create(:user, :email=> 'another@dude.com', :is_member => true)
      email_to_send = create(:email_with_tokens, :delayed_job_id => 666)
      User.stub(:select) { raise Exception.new("Damn!") }
      email_to_send.deliver_blast_in_batches([user1, user2].map(&:id), 1)

      PushLog.count.should eql 2
      email_to_send.delayed_job_id.should == 666 # cleared by BlastJob not email
    end
  end

  describe "#create_subject_line_tests" do
    let!(:base_name){ 'test subject line' }
    let!(:proofed_email){ create(:email, name: "#{base_name} - test subject 1") }
    let!(:email_subjects){ ['test subject 2', 'test subject 3'] }
    before{ proofed_email.update_attribute(:test_sent_at, Time.now) }

    it "should create multiple emails for each subject" do
      proofed_email.create_subject_line_tests!(email_subjects)
      email_subjects.each do |subject_line|
        test_email = proofed_email.blast.emails.where(name: "[SUBJECT LINE TEST] #{base_name} - #{subject_line}", subject: subject_line).first
        expect(test_email)
        expect(test_email.body).to eq(proofed_email.body)
        expect(test_email.blast).to eq(proofed_email.blast)
        expect(test_email.proofed?)
        expect(test_email.subject_line_test?)
      end
    end
  end

  describe "#has_been_sent?" do
    context "email has been sent in the past" do
      let(:email) { create(:email) }
      before { create(:sent_email, email: email) }

      specify { email.has_been_sent?.should == true }
    end

    context "email has never been sent" do
      let(:email) { create(:email) }
      specify { email.has_been_sent?.should == false }
    end
  end
end
