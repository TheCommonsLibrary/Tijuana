require File.expand_path(File.dirname(__FILE__) + '../../spec_helper')

def assert_html_footer_correct
  footer = "GetUp is an independent, not-for-profit community campaigning group. We use new technology to empower Australians to have their say on important national issues. We receive no political party or government funding, and every campaign we run is entirely supported by voluntary donations. If you'd like to contribute to help fund GetUp's work, please <a href=\"https://#{AppConstants.host}/donate?t={TRACKING_HASH|NOT_AVAILABLE}\">donate now!</a> This email was sent to {EMAIL|NOT_AVAILABLE}. To unsubscribe this email address from GetUp, please click <a href=\"http://#{AppConstants.host}/unsubscribe?t={TRACKING_HASH|NOT_AVAILABLE}\">here</a>."
  acknowledgement_of_country = "Our team acknowledges that we meet and work on the land of the Gadigal people of the Eora Nation. We wish to pay respect to their Elders - past, present and future - and acknowledge the important role all Aboriginal and Torres Strait Islander people continue to play within Australia and the GetUp community."
  address = "Authorised by #{AppConstants.authorised_by}, #{AppConstants.office_address}"
  @delivered.html_part.body.should include footer
  @delivered.html_part.body.should include acknowledgement_of_country
  @delivered.html_part.body.should include address
end

def assert_plain_text_footer_correct
  footer = "GetUp is an independent, not-for-profit community campaigning group. We use new technology to empower Australians to have their say on important national issues. We receive no political party or government funding, and every campaign we run is entirely supported by voluntary donations. If you'd like to contribute to help fund GetUp's work, please go to https://#{AppConstants.host}/donate?t={TRACKING_HASH|NOT_AVAILABLE}. To unsubscribe from GetUp, please go to http://#{AppConstants.host}/unsubscribe?t={TRACKING_HASH|NOT_AVAILABLE}."
  acknowledgement_of_country = "Our team acknowledges that we meet and work on the land of the Gadigal people of the Eora Nation. We wish to pay respect to their Elders - past, present and future - and acknowledge the important role all Aboriginal and Torres Strait Islander people continue to play within Australia and the GetUp community."
  address = "Authorised by #{AppConstants.authorised_by}, #{AppConstants.office_address}"
  @delivered.text_part.body.should include footer
  @delivered.text_part.body.should include acknowledgement_of_country
  @delivered.text_part.body.should include address
end

describe 'Emailer' do
  before do
    ActionMailer::Base.deliveries = []
    UserMailer.stub(:welcome_to_getup_email) { double(:deliver=>nil) }
  end

  it 'should send thankyou email' do
    Emailer.thankyou_email("user@email.com", "Subjective subject", "Lorem ipsum").deliver
    ActionMailer::Base.deliveries.size.should eql(1)
    @delivered = ActionMailer::Base.deliveries.last
    @delivered.should have_body_text(/Lorem ipsum/)
    @delivered.should have_subject(/Subjective subject/)
    @delivered.should deliver_to("user@email.com")
  end
  
  describe "target email" do
    it "correctly breaks up a list with comma delimiters" do
      email = Emailer.target_email("bob@bobson.com,mrsanchez@gomez.com, juan@pablo.com", "", "", "", "")
      email.should deliver_to(["bob@bobson.com", "mrsanchez@gomez.com", "juan@pablo.com"])
    end
    
    it "correctly breaks up a list with space delimiters" do
      email = Emailer.target_email("bob@bobson.com mrsanchez@gomez.com  juan@pablo.com", "", "", "", "")
      email.should deliver_to(["bob@bobson.com", "mrsanchez@gomez.com", "juan@pablo.com"])
    end
    
    it "correctly breaks up a list with semi-colon delimiters" do
      email = Emailer.target_email("bob@bobson.com;mrsanchez@gomez.com; juan@pablo.com", "", "", "", "")
      email.should deliver_to(["bob@bobson.com", "mrsanchez@gomez.com", "juan@pablo.com"])
    end

    it "should not embed a tracking image by default" do
      Emailer.target_email("bob@bobson.com", "info@getup.org.au", '', "a subject", "a message").deliver
      ActionMailer::Base.deliveries.size.should eql(1)
      ActionMailer::Base.deliveries.last.html_part.body.should_not include "beacon.gif"
    end

    context "with the tracking_token argument set" do
      let!(:token){ "xysfa2sdfs" }
      before do
        Emailer.target_email("bob@bobson.com", "info@getup.org.au", '', "a subject", "a message", token).deliver
      end
      let(:email_html){ ActionMailer::Base.deliveries.last.html_part.body }

      it "should embed a tracking image with the tracking token in the url" do
        email_html.should include "http://#{AppConstants.host}/emailer/#{token}/beacon.gif"
      end
    end
  end

  describe "email blast" do
    it "should send the email to sendgrid, with the corresponding API headers" do
      donald = create(:leo, :first_name => "Donald")
      steve = create(:brazilian_dude, :first_name => "Steve")
      push = create(:push)
      blast = create(:blast, push: push)
      email_to_send = create(:email_with_tokens, :from_address => "info@getup.org.au", :reply_to_address => "reply@getup.org.au", :footer => "getup", blast: blast)

      Emailer.blast(email_to_send, :recipients => ['another@dude.com', 'leonardo@borges.com']).deliver
                      
      ActionMailer::Base.deliveries.size.should eql(1)

      @delivered = ActionMailer::Base.deliveries.last
      @delivered.should have_body_text(/\{NAME\|Friend\}/)
      @delivered.should have_body_text(/\{POSTCODE\|Nowhere\}/)
      @delivered.should have_body_text(/t=\{TRACKING_HASH\|NOT_AVAILABLE\}/)
      @delivered.should have_body_text("<img src=\"http://#{AppConstants.host}/beacon.gif?t={TRACKING_HASH\|NOT_AVAILABLE\}\">")
      @delivered.html_part.body.should include "Pls click <a href=\"http://somewhere.com?t={TRACKING_HASH|NOT_AVAILABLE}\">http://somewhere.com</a>"
      @delivered.text_part.body.should match(/Pls click http:\/\/somewhere.com?(.*)t={TRACKING_HASH|NOT_AVAILABLE}/)

      #FOOTER
      assert_html_footer_correct
      assert_plain_text_footer_correct

      @delivered.should have_subject(/Yes, \{NAME\|Friend\}, we can!/)
      @delivered.should deliver_to("does-not-matter@getup.org.au")

      sendgrid_header = JSON.parse(@delivered.header['X-SMTPAPI'].to_s)
      expect(["another@dude.com", "leonardo@borges.com"]).to match_array(sendgrid_header["to"])
      expect("P#{push.id}_B#{blast.id}_E#{email_to_send.id}").to eq sendgrid_header["category"]
      substitutions = {
        "{NAME|Friend}" => [ "Steve", "Donald" ],
        "{POSTCODE|Nowhere}" => [ "9999", "9999" ],
        "{TRACKING_HASH|NOT_AVAILABLE}" => [ EmailTrackingToken.encode(steve.id, email_to_send.id), EmailTrackingToken.encode(donald.id, email_to_send.id) ],
        "{EMAIL|NOT_AVAILABLE}"=>["another@dude.com", "leonardo@borges.com"]
      }
      expect(sendgrid_header["sub"]).to eq(substitutions)

      filters = {
        "ganalytics" => {
          "settings" => {
            "enable" => "1", "utm_source" => "blast", "utm_medium" => "email",
            "utm_campaign" => "_TEST_Yes___NAME_Friend___we_can__",
            "utm_content" => email_to_send.id.to_s
          }
        }
      }
      expect(sendgrid_header["filters"]).to eq(filters)

      @delivered.should have_header("from", "GetUp! <info@getup.org.au>")
      @delivered.should have_header("reply-to", "reply@getup.org.au")
      @delivered.should have_header("content-type", /multipart/)
    end

    it "should NOT send emails to domains other than @getup.org.au or emailtests.com if not in production or test mode" do
      recipients = ['leonardo@gmail.com', 'another@emailtests.com', 'not-me@hotmail.com', 'david@getup.org.au']
      recipients.each do |email|
        create(:user, :email => email)
      end
      email_to_send = create(:email_with_tokens, :from_address => "info@getup.org.au", :reply_to_address => "reply@getup.org.au", :footer => "getup")
      Rails.stub(:env).and_return(ActiveSupport::StringInquirer.new('staging'))
      Emailer.blast(email_to_send, :recipients => recipients).deliver
      ActionMailer::Base.deliveries.size.should eql(1)
      @delivered = ActionMailer::Base.deliveries.last
      @delivered.header['X-SMTPAPI'].value.should match(/another@emailtests.com/)
      @delivered.header['X-SMTPAPI'].value.should match(/david@getup.org.au/)
      @delivered.header['X-SMTPAPI'].value.should_not match(/not-me@hotmail.com/)
      @delivered.header['X-SMTPAPI'].value.should_not match(/leonardo@gmail.com/)
    end

    it "should send emails to all domains when in production environment" do
      recipients = ['leonardo@gmail.com', 'another@thoughtworks.com', 'not-me@hotmail.com', 'david@getup.org.au']
      recipients.each do |email|
        create(:user, :email => email)
      end
      email_to_send = create(:email_with_tokens, :from_address => "info@getup.org.au", :reply_to_address => "reply@getup.org.au", :footer => "getup")
      Rails.stub(:env).and_return(ActiveSupport::StringInquirer.new('production'))
      Emailer.blast(email_to_send, :recipients => recipients).deliver
      ActionMailer::Base.deliveries.size.should eql(1)
      @delivered = ActionMailer::Base.deliveries.last
      @delivered.header['X-SMTPAPI'].value.should match(/another@thoughtworks.com/)
      @delivered.header['X-SMTPAPI'].value.should match(/david@getup.org.au/)
      @delivered.header['X-SMTPAPI'].value.should match(/not-me@hotmail.com/)
      @delivered.header['X-SMTPAPI'].value.should match(/leonardo@gmail.com/)
    end

    it "should send emails to all domains when in test environment" do
      recipients = ['leonardo@gmail.com', 'another@thoughtworks.com', 'not-me@hotmail.com', 'david@getup.org.au']
      recipients.each do |email|
        create(:user, :email => email)
      end
      email_to_send = create(:email_with_tokens, :from_address => "info@getup.org.au", :reply_to_address => "reply@getup.org.au", :footer => "getup")
      Rails.stub(:env).and_return(ActiveSupport::StringInquirer.new('test'))
      Emailer.blast(email_to_send, :recipients => recipients).deliver
      ActionMailer::Base.deliveries.size.should eql(1)
      @delivered = ActionMailer::Base.deliveries.last
      @delivered.header['X-SMTPAPI'].value.should match(/another@thoughtworks.com/)
      @delivered.header['X-SMTPAPI'].value.should match(/david@getup.org.au/)
      @delivered.header['X-SMTPAPI'].value.should match(/not-me@hotmail.com/)
      @delivered.header['X-SMTPAPI'].value.should match(/leonardo@gmail.com/)
    end

    it "should prepend a test string to the email subject if in test mode" do
      user1 = create(:leo, :first_name => "Donald")
      email_to_send = create(:email_with_tokens, :subject=> "Meltdown!", :from_address => "info@getup.org.au", :reply_to_address => "reply@getup.org.au", :footer => "getup")
      user1_hash = EmailTrackingToken.encode(user1.id, email_to_send.id)

      Emailer.blast(email_to_send, :recipients => ['leonardo@borges.com'], :test => true).deliver

      ActionMailer::Base.deliveries.size.should eql(1)

      @delivered = ActionMailer::Base.deliveries.last
      @delivered.should have_subject(/\[TEST\]Meltdown!/)
    end

    it "should prepend a showcase string to the email subject if in showcase environment" do
      user1 = create(:leo, :first_name => "Donald")
      email_to_send = create(:email_with_tokens, :subject=> "Meltdown!", :from_address => "info@getup.org.au", :reply_to_address => "reply@getup.org.au", :footer => "getup")
      user1_hash = EmailTrackingToken.encode(user1.id, email_to_send.id)
      Rails.stub(:env).and_return(ActiveSupport::StringInquirer.new('showcase'))
      Emailer.blast(email_to_send, :recipients => ['leonardo@getup.org.au']).deliver
      ActionMailer::Base.deliveries.size.should eql(1)
      @delivered = ActionMailer::Base.deliveries.last
      @delivered.should have_subject(/\[SHOWCASE\]Meltdown!/)
    end

    it "should prepend a test and showcase string to the email subject if in showcase environment and test mode" do
      user1 = create(:leo, :first_name => "Donald")
      email_to_send = create(:email_with_tokens, :subject=> "Meltdown!", :from_address => "info@getup.org.au", :reply_to_address => "reply@getup.org.au", :footer => "getup")
      user1_hash = EmailTrackingToken.encode(user1.id, email_to_send.id)
      Rails.stub(:env).and_return(ActiveSupport::StringInquirer.new('showcase'))
      Emailer.blast(email_to_send, :recipients => ['leonardo@getup.org.au'], :test => true).deliver
      ActionMailer::Base.deliveries.size.should eql(1)
      @delivered = ActionMailer::Base.deliveries.last
      @delivered.should have_subject(/\[TEST\]\[SHOWCASE\]Meltdown!/)
    end

    it "should raise a RuntimeError if the size of the tokens array doesn't match the number of recipients" do
      email_to_send = create(:email_with_tokens, :subject=> "Meltdown!", :from_address => "info@getup.org.au", :reply_to_address => "reply@getup.org.au")

      expect {Emailer.blast(email_to_send, :recipients => ['leonardo@borges.com','dave@mustaine.com', 'james@hetfield.com']).deliver}.to raise_error(RuntimeError)
    end

    it "should allow token link to be manually generated in custom fragments" do
      user1 = create(:leo, :first_name => "Donald")
      email_to_send = create(:email_with_custom_fragment, :subject=> "Meltdown!", :from_address => "info@getup.org.au", :reply_to_address => "reply@getup.org.au", :footer => "getup")
      user1_hash = EmailTrackingToken.encode(user1.id, email_to_send.id)
      Emailer.blast(email_to_send, :recipients => [user1.email]).deliver
      ActionMailer::Base.deliveries.size.should eql(1)
      @delivered = ActionMailer::Base.deliveries.last
      @delivered["X-SMTPAPI"].to_s.should include "/vision2014?t=#{URI.encode_www_form_component(user1_hash)}"
    end
  end
end
