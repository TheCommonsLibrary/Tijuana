require File.expand_path(File.dirname(__FILE__) + "../../spec_helper")

describe Emailer do

  let(:deliveries) { ActionMailer::Base.deliveries }
  let(:email) { ActionMailer::Base.deliveries.first }

  before(:each) { deliveries.clear }

  describe '#one_off_receipt_email' do
    let(:transaction) { create(:transaction) }
    before { Emailer.one_off_receipt_email(transaction.donation, [transaction]).deliver }
    specify { expect(email.subject).to match(/Thanks for your donation/) }
    specify { expect(email.body).to match(/Thanks for chipping in/) }
  end

  context '#recurring_receipt_email' do
    let(:recurring_transaction) { create(:transaction, donation: create(:recurring_donation)) }
    before{ Emailer.recurring_receipt_email(recurring_transaction.donation, [recurring_transaction]).deliver }
    specify{ expect(email.subject).to match(/Welcome to the GetUp Crew/) }
    specify{ expect(email.body).to match(/Crew/) }
  end

  describe '#refund_receipt_email' do
    let(:transaction) { FactoryGirl.create(:transaction) }
    before { transaction.donation.stub(:made_to) { 'Testing 123' } }
    before { Emailer.refund_receipt_email(transaction).deliver }
    specify { expect(email.subject).to match(/Refunded Transaction from GetUp/) }
    specify { expect(email.body).to match(/Thanks for your past support of GetUp/) }
    specify { expect(deliveries.last.body).to include('Campaign: Testing 123') }
  end

  describe '#cancelled_recurring_donation_email' do
      before { Emailer.cancelled_recurring_donation_email(create(:donation)).deliver }
      specify { email.subject.match(/Cancelled GetUp Crew Donation/) }
  end

  context "test environment" do
    before(:each) do
      Rails.env.stub(:production? => false)
      Rails.env.stub(:test? => true)
    end

    it "should send emails to MPs email addresses" do
      Emailer.target_email("tony@aus.gov.au, malcolm@aus.gov.au", "dude@test.com", nil, "Hello from dude", "Nope, Nope, Nope!").deliver
      deliveries[0].to.should == %w(tony@aus.gov.au malcolm@aus.gov.au)
    end
  end

  context "prod environment" do
    before(:each) do
      Rails.env.stub(:production? => true)
      Rails.env.stub(:test? => false)
    end

    it "should send emails to MPs email addresses" do
      Emailer.target_email("tony@aus.gov.au, malcolm@aus.gov.au", "dude@test.com", nil, "Hello from dude", "Nope, Nope, Nope!").deliver
      deliveries[0].to.should == %w(tony@aus.gov.au malcolm@aus.gov.au)
    end
  end

  context "showcase" do
    before(:each) do
      Rails.env.stub(:production? => false)
      Rails.env.stub(:test? => false)
    end

    it "should not send emails to a single MP in other environments" do
      Emailer.target_email("tony@aus.gov.au", "dude@test.com", nil, "Hello from dude", "Nope, Nope, Nope!").deliver
      deliveries[0].to.should eq ['tech-dev+tony_aus.gov.au@getup.org.au']
    end

    it "should not send emails to multiple MPs in other environments" do
      Emailer.target_email("tony@aus.gov.au, malcolm@aus.gov.au", "dude@test.com", nil, "Hello from dude", "Nope, Nope, Nope!").deliver
      deliveries[0].to.should eq ['tech-dev+tony_aus.gov.au&malcolm_aus.gov.au@getup.org.au']
    end
  end

  describe ".blast" do
    before{ ActionMailer::Base.deliveries = [] }

    context "with default footer" do
      let!(:email){ create(:email) }
      let!(:user){ create(:user) }
      before{ Emailer.blast(email, :recipients => [user.email]).deliver }

      it "should include a substition tag and corresponding Sendgrid header for the recipients email" do
        email = ActionMailer::Base.deliveries.first
        expect(JSON.parse(email.header['X-SMTPAPI'].value)['sub']['{EMAIL|NOT_AVAILABLE}'].first).to eq(user.email)
        expect(email.html_part.body.to_s).to be_include('{EMAIL|NOT_AVAILABLE}')
      end
    end

    context "with an email that is a html document" do
      let(:html_document) { "<!DOCTYPE html><html>\n<body>test test</body></html>" }
      let!(:email_with_body_is_html_doc){ create(:email, body: html_document, body_is_html_document: true) }
      before{ Emailer.blast(email_with_body_is_html_doc, :recipients => ['leonardo@borges.com']).deliver }

      it "should not do any conversions to the html such as adding line breaks" do
        expect(ActionMailer::Base.deliveries.first.html_part.body).to_not be_include('<br/>')
      end

      it "should not include the default footer in the text part" do
        expect(ActionMailer::Base.deliveries.first.text_part.body.to_s).to eq("\ntest test\n\n\n")
      end

      it "should append the beacon image to the end of the body" do
        expect(ActionMailer::Base.deliveries.first.html_part.body.to_s).to be_include('<img src="http://localhost/beacon.gif?t={TRACKING_HASH|NOT_AVAILABLE}"></body>')
      end
    end
  end
end
