require File.dirname(__FILE__) + '/../spec_helper.rb'
require 'timecop'

describe "DonationTriggerService" do
  let(:weekly_donor) { FactoryGirl.create(:user, email: "weekly_donor@user.com") }
  let(:monthly_donor) { FactoryGirl.create(:user, email: "monthly_donor@user.com") }
  let(:annual_donor) { FactoryGirl.create(:user, email: "annual_donor@user.com") }
  let(:weekly_failed_donation) { FactoryGirl.create(:donation,
                                         :user => weekly_donor,
                                         :card_number => PaymentGateways::CARD_FAILURE,
                                         :frequency => "weekly",
                                         :card_expiry_month => "03",
                                         :card_expiry_year => "15")}
  let(:monthly_failed_donation) { FactoryGirl.create(:donation,
                                         :user => monthly_donor,
                                         card_number: '34711111111111111111', # amex card
                                         :frequency => "monthly",
                                         :card_expiry_month => "03",
                                         :card_expiry_year => "15")}
  let(:annual_failed_donation) { FactoryGirl.create(:donation,
                                         :user => annual_donor,
                                         :card_number => PaymentGateways::CARD_FAILURE,
                                         :frequency => "annual",
                                         :card_expiry_month => "03",
                                         :card_expiry_year => "15")}

  before :each do
    Timecop.freeze(Time.local(2015, 03, 22))
    ActionMailer::Base.deliveries.clear
  end

  after :each do
    Timecop.return
    ActionMailer::Base.deliveries.clear
  end

  it "should NOT send email if donation does not have successful transaction before" do
    Timecop.travel(Time.local(2015, 03, 22))
    DonationTriggerService.new.fire_trigger

    SentTriggerEmail.all.size.should == 0
  end

  context "trigger_expiring_card" do
    #must have successful transaction
    let!(:weekly_successful_transaction) {FactoryGirl.create(:transaction, donation: weekly_failed_donation)}
    let!(:monthly_successful_transaction) {FactoryGirl.create(:transaction, donation: monthly_failed_donation)}
    let!(:annual_successful_transaction) {FactoryGirl.create(:transaction, donation: annual_failed_donation)}

    {'this month' => Time.local(2015, 03, 01), 'next month' => Time.local(2015, 02, 01)}.each do |month, new_date|
      it "should send expiring card email to users whose credit card will expire #{month}" do
        Timecop.travel(new_date)
        DonationTriggerService.new.fire_trigger

        SentTriggerEmail.where(key: 'expiring_card_email').size.should == 3

        ActionMailer::Base.deliveries.size.should == 3
        ActionMailer::Base.deliveries.first.body.should =~ /The card you are using for your GetUp Crew donations is set to expire/
      end
    end


    {visa: '4111111111111111', mastercard: '5111111111111111'}.each do |card_type, card_number|
      it "should NOT send expiring card email #{card_type} users" do
        [weekly_failed_donation, annual_failed_donation].each(&:destroy)
        monthly_failed_donation.update_attributes!(card_number: card_number)
        expect(monthly_failed_donation.card_type).to eq(card_type.to_s)
        Timecop.travel(Time.local(2015, 03, 01))
        DonationTriggerService.new.fire_trigger
        email_log = SentTriggerEmail.where(user_id: monthly_donor.id, key: 'expiring_card_email')
        email = ActionMailer::Base.deliveries.first

        email_log.first.should be_nil
        email.should be_nil
      end
    end


    it "should NOT send expiring card email twice to same user" do
      Timecop.travel(Time.local(2015, 03, 22))
      2.times { DonationTriggerService.new.fire_trigger }

      ActionMailer::Base.deliveries.size.should == 3
    end

    it "should send expiring card email if card is going to be expired again after one month from previous expiring mail" do
      Timecop.travel(Time.local(2015, 03, 22))
      DonationTriggerService.new.fire_trigger
      ActionMailer::Base.deliveries.size.should == 3

      # Weekly donation's card has been updated
      weekly_failed_donation.card_expiry_month = 4
      weekly_failed_donation.card_expiry_year = 2015
      weekly_failed_donation.save!

      Timecop.travel(Time.local(2015, 04, 22))
      DonationTriggerService.new.fire_trigger
      ActionMailer::Base.deliveries.size.should == 4
    end
  end

  context "failing and have sent donation follow up but then the card is successful and then one year later, the card fails again" do
    #must have successful transaction before failed transaction
    let!(:weekly_successful_transaction) {FactoryGirl.create(:transaction, donation: weekly_failed_donation, created_at: Time.local(2015, 03, 8))}
    let!(:monthly_successful_transaction) {FactoryGirl.create(:transaction, donation: monthly_failed_donation, created_at: Time.local(2015, 03, 22))}
    let!(:annual_successful_transaction) {FactoryGirl.create(:transaction, donation: annual_failed_donation, created_at: Time.local(2015, 03, 22))}

    #failed transaction
    let!(:weekly_failed_transaction_1) { FactoryGirl.create(:failed_transaction, :donation => weekly_failed_donation, :created_at => Time.local(2015, 03, 22))}
    let!(:weekly_failed_transaction_2) { FactoryGirl.create(:failed_transaction, :donation => weekly_failed_donation, :created_at => Time.local(2015, 03, 15))}
    context "trigger_failing" do
      it "should send failing donation emails when weekly donation failed 2 times consecutively or monthly/annual donation fails" do
        DonationTriggerService.new.fire_trigger
        SentTriggerEmail.where(key: 'donation_failing_email').size.should == 1

        Timecop.travel(Time.local(2015, 04, 22))
        DonationTriggerService.new.fire_trigger
        SentTriggerEmail.where(key: 'donation_failing_follow_up_email').size.should == 1

        Timecop.travel(Time.local(2015, 04, 22))
        create(:transaction, :donation => weekly_failed_donation)
        DonationTriggerService.new.fire_trigger
        SentTriggerEmail.where(key: 'cancellation_warning_email').size.should be_zero

        Timecop.travel(Time.local(2016, 03, 22))
        2.times{ create(:failed_transaction, :donation => weekly_failed_donation) }
        DonationTriggerService.new.fire_trigger
        SentTriggerEmail.where(key: 'donation_failing_email').size.should == 2
        SentTriggerEmail.where(key: 'cancellation_warning_email').size.should be_zero
      end
    end
  end

  context "failing donation" do
    #must have successful transaction before failed transaction
    let!(:weekly_successful_transaction) {FactoryGirl.create(:transaction, donation: weekly_failed_donation, created_at: Time.local(2015, 03, 8))}
    let!(:monthly_successful_transaction) {FactoryGirl.create(:transaction, donation: monthly_failed_donation, created_at: Time.local(2015, 03, 15))}
    let!(:annual_successful_transaction) {FactoryGirl.create(:transaction, donation: annual_failed_donation, created_at: Time.local(2015, 03, 15))}

    #failed transaction
    let!(:weekly_failed_transaction_1) { FactoryGirl.create(:failed_transaction, :donation => weekly_failed_donation, :created_at => Time.local(2015, 03, 22))}
    let!(:weekly_failed_transaction_2) { FactoryGirl.create(:failed_transaction, :donation => weekly_failed_donation, :created_at => Time.local(2015, 03, 15))}
    
    let!(:monthly_failed_transaction) { FactoryGirl.create(:failed_transaction, :donation => monthly_failed_donation, :created_at => Time.local(2015, 03, 22))}
    let!(:annual_failed_transaction) { FactoryGirl.create(:failed_transaction, :donation => annual_failed_donation, :created_at => Time.local(2015, 03, 22))}

    it "should send all emails" do
      Timecop.travel(Time.local(2015, 03, 22))
      trigger_service = DonationTriggerService.new

      trigger_service.fire_trigger
      ActionMailer::Base.deliveries.size.should == 6 # 3 expiring card email, 3 failing donation emails

      Timecop.travel(Time.local(2015, 04, 22))
      trigger_service.fire_trigger
      ActionMailer::Base.deliveries.size.should == 9 # plus 3 failing donation follow up emails

      Timecop.travel(Time.local(2015, 05, 22))
      trigger_service.fire_trigger
      ActionMailer::Base.deliveries.size.should == 12 # plus 3 cancellation warning emails
    end

    context "trigger_failing" do
      it "should send failing donation emails when weekly donation failed 2 times consecutively or monthly/annual donation fails" do
        DonationTriggerService.new.trigger_failing

        SentTriggerEmail.where(key: 'donation_failing_email').size.should == 3
        ActionMailer::Base.deliveries.first.body.should =~ /We noticed your (weekly|monthly|annual) GetUp Crew donation of \$30\.00 hasn\'t been processing recently and we\'d like to help you fix that/
      end

      it "should resend failing donation email after weekly donation has successful transaction then has consecutive failures again" do
        DonationTriggerService.new.trigger_failing
        FactoryGirl.create(:transaction, donation: weekly_failed_donation, created_at: Time.local(2015, 03, 22))
        FactoryGirl.create(:failed_transaction, donation: weekly_failed_donation, created_at: Time.local(2015, 03, 29))
        FactoryGirl.create(:failed_transaction, donation: weekly_failed_donation, created_at: Time.local(2015, 04, 05))

        Timecop.travel(Time.local(2015, 04, 22))
        
        $debugging = true
        DonationTriggerService.new.trigger_failing

        SentTriggerEmail.where(user_id: weekly_failed_donation.user.id, key: 'donation_failing_email').size.should == 2
      end

      context 'when the failure is system related' do
        let(:weekly_donation) { FactoryGirl.create(:recurring_donation) }
        let(:monthly_donation) { FactoryGirl.create(:recurring_donation, frequency: 'monthly') }
        let(:yearly_donation) { FactoryGirl.create(:recurring_donation, frequency: 'annual') }
        # successful txn so not fraud
        let!(:txn1) { FactoryGirl.create(:transaction, donation: weekly_donation) }
        let!(:txn2) { FactoryGirl.create(:transaction, donation: monthly_donation) }
        let!(:txn3) { FactoryGirl.create(:transaction, donation: yearly_donation) }
        # weekly needs 2 consecutive failures
        let!(:failed_txn1) { FactoryGirl.create(:failed_transaction, donation: weekly_donation) }
        let!(:weekly_system_failure) { FactoryGirl.create(:failed_system_transaction, donation: weekly_donation) }
        let!(:monthly_system_failure) { FactoryGirl.create(:failed_system_transaction, donation: monthly_donation) }
        let!(:annual_system_failure) { FactoryGirl.create(:failed_system_transaction, donation: yearly_donation) }
        let(:ids) { [weekly_donation.id, monthly_donation.id, yearly_donation.id] }
        before { DonationTriggerService.new.trigger_failing }
        specify { expect(SentTriggerEmail.all.map(&:triggered_by).map(&:id)).not_to include(*ids) }
      end
    end

    context "trigger_failing_follow_up" do
      it "should send failing follow up email 1 month after sending failing donation email and flag that donation" do
        DonationTriggerService.new.trigger_failing

        Timecop.travel(Time.local(2015, 04, 22))
        DonationTriggerService.new.fire_trigger

        weekly_failed_donation.reload
        weekly_failed_donation.flagged_because.should == "Sent failing follow up email"
        weekly_failed_donation.dismissed_at.should be_nil
        SentTriggerEmail.where(key: 'donation_failing_follow_up_email').size.should == 3
        ActionMailer::Base.deliveries.last.body.should =~ /We're contacting you again because your (weekly|monthly|annual) GetUp Crew donation of \$30\.00 still hasn't been processing recently and we'd like to help you fix that/
      end

      it "should NOT send failing follow up email if that donation has successful transaction within 1 month from the time donation failing email has been sent" do
        DonationTriggerService.new.trigger_failing
        FactoryGirl.create(:transaction, donation: weekly_failed_donation, created_at: Time.local(2015, 03, 29))
        FactoryGirl.create(:transaction, donation: monthly_failed_donation, created_at: Time.local(2015, 03, 29))
        FactoryGirl.create(:transaction, donation: annual_failed_donation, created_at: Time.local(2015, 03, 29))

        Timecop.travel(Time.local(2015, 04, 22))
        DonationTriggerService.new.fire_trigger

        SentTriggerEmail.where(key: 'donation_failing_follow_up_email').should be_blank
      end
    end

    context "trigger_cancellation_warning" do
      it "should send email cancellation warning email 1 month after sending failing follow up donation email" do
        SentTriggerEmail.create(user_id: weekly_donor.id, sent_date: Time.local(2015, 03, 22), key: :donation_failing_follow_up_email, triggered_by: weekly_failed_donation)
        Timecop.travel(Time.local(2015, 04, 22))
        DonationTriggerService.new.trigger_failing

        email_log = SentTriggerEmail.where(key: 'cancellation_warning_email')
        weekly_email = ActionMailer::Base.deliveries.first

        weekly_failed_donation.reload
        weekly_failed_donation.flagged_because.should == "Sent cancellation warning email"
        weekly_failed_donation.dismissed_at.should be_nil

        email_log.size.should == 1
        weekly_email.body.should =~ /(weekly|monthly|annual) GetUp Crew donation of \$30\.00 has been unsuccessful for three months./
      end

      it "should NOT send cancellation warning email if that donation currently has successful transaction" do
        SentTriggerEmail.create(user_id: weekly_donor.id, sent_date: Time.local(2015, 03, 22), key: :donation_failing_follow_up_email, triggered_by: weekly_failed_donation)
        SentTriggerEmail.create(user_id: monthly_donor.id, sent_date: Time.local(2015, 03, 22), key: :donation_failing_follow_up_email, triggered_by: monthly_failed_donation)
        SentTriggerEmail.create(user_id: annual_donor.id, sent_date: Time.local(2015, 03, 22), key: :donation_failing_follow_up_email, triggered_by: annual_failed_donation)
        FactoryGirl.create(:transaction, donation: weekly_failed_donation, created_at: Time.local(2015, 03, 22))
        FactoryGirl.create(:failed_transaction, donation: weekly_failed_donation, created_at: Time.local(2015, 03, 29))
        FactoryGirl.create(:transaction, donation: monthly_failed_donation, created_at: Time.local(2015, 03, 22))
        FactoryGirl.create(:transaction, donation: annual_failed_donation, created_at: Time.local(2015, 03, 22))

        Timecop.travel(Time.local(2015, 04, 22))
        DonationTriggerService.new.trigger_failing

        SentTriggerEmail.where(key: 'cancellation_warning_email').size.should == 0
      end
    end
  end

  describe "#last_failure_email" do
    it "should return nil if there is no failure email" do
      DonationTriggerService.new.last_failure_email(weekly_failed_donation).should be_nil
      DonationTriggerService.new.last_failure_email(monthly_failed_donation).should be_nil
      DonationTriggerService.new.last_failure_email(annual_failed_donation).should be_nil
    end

    it "should return last failure email that has been sent" do
      SentTriggerEmail.create(
                              user_id: weekly_failed_donation.user_id,
                              key: :donation_failing_email,
                              triggered_by: weekly_failed_donation,
                              sent_date: Time.local(2015, 03, 22)
      )
      SentTriggerEmail.create(
                              user_id: weekly_failed_donation.user_id,
                              key: :donation_failing_follow_up_email,
                              triggered_by: weekly_failed_donation,
                              sent_date: Time.local(2015, 03, 24)
      )
      last_failure_email = DonationTriggerService.new.last_failure_email(weekly_failed_donation)
      last_failure_email.should_not be_nil
      last_failure_email[:key].should == "donation_failing_follow_up_email"
      last_failure_email[:user_id].should == weekly_failed_donation.user_id
      last_failure_email[:triggered_by_id].should == weekly_failed_donation.id
      last_failure_email[:triggered_by_type].should == "Donation"
    end
  end
  context "flags donation" do
    #failed transaction
    let!(:weekly_failed_transaction_1) { FactoryGirl.create(:failed_transaction, :donation => weekly_failed_donation, :created_at => Time.local(2015, 03, 22)) }
    let!(:weekly_failed_transaction_2) { FactoryGirl.create(:failed_transaction, :donation => weekly_failed_donation, :created_at => Time.local(2015, 03, 15)) }
    
    let!(:monthly_failed_transaction) { FactoryGirl.create(:failed_transaction, :donation => monthly_failed_donation, :created_at => Time.local(2015, 03, 22)) }
    let!(:annual_failed_transaction) { FactoryGirl.create(:failed_transaction, :donation => annual_failed_donation, :created_at => Time.local(2015, 03, 22)) }

    it "should flag donation which received a failing follow up email or cancellation warning email" do
      #must have successful transaction before failed transaction
      FactoryGirl.create(:transaction, donation: weekly_failed_donation, created_at: Time.local(2015, 03, 8))
      FactoryGirl.create(:transaction, donation: monthly_failed_donation, created_at: Time.local(2015, 03, 15))
      FactoryGirl.create(:transaction, donation: annual_failed_donation, created_at: Time.local(2015, 03, 15))

      Timecop.travel(Time.local(2015, 03, 22))
      fire_trigger_and_check_no_flagging

      Timecop.travel(Time.local(2015, 04, 22))
      fire_trigger_and_check_flagged_because_on_donations_is("Sent failing follow up email")

      Timecop.travel(Time.local(2015, 05, 22))
      fire_trigger_and_check_flagged_because_on_donations_is("Sent cancellation warning email")
    end

    it "should only flag once when email sent" do
      FactoryGirl.create(:transaction, donation: weekly_failed_donation, created_at: Time.local(2015, 03, 8))
      FactoryGirl.create(:transaction, donation: monthly_failed_donation, created_at: Time.local(2015, 03, 15))
      FactoryGirl.create(:transaction, donation: annual_failed_donation, created_at: Time.local(2015, 03, 15))

      Timecop.travel(Time.local(2015, 03, 22))
      fire_trigger_and_check_no_flagging

      Timecop.travel(Time.local(2015, 04, 22))
      fire_trigger_and_check_flagged_since_on_donations_is(Time.local(2015, 04, 22))

      Timecop.travel(Time.local(2015, 04, 30))
      fire_trigger_and_check_flagged_since_on_donations_is(Time.local(2015, 04, 22))

      Timecop.travel(Time.local(2015, 05, 22))
      fire_trigger_and_check_flagged_since_on_donations_is(Time.local(2015, 05, 22))
    end

    it "should not flag when donation has no successful transactions" do
      #email has been sent manually
      SentTriggerEmail.create(user_id: weekly_failed_donation.user.id,
                              key: :donation_failing_email,
                              triggered_by: weekly_failed_donation,
                              sent_date: Time.local(2015, 03, 22)
                             )

      Timecop.travel(Time.local(2015, 03, 22))
      fire_trigger_and_check_no_flagging

      Timecop.travel(Time.local(2015, 04, 22))
      fire_trigger_and_check_no_flagging

      Timecop.travel(Time.local(2015, 05, 22))
      fire_trigger_and_check_no_flagging
    end

    it "should not flag when received email and had successful transaction" do
      #email has been sent manually
      SentTriggerEmail.create(user_id: weekly_failed_donation.user.id,
                              key: :donation_failing_email,
                              triggered_by: weekly_failed_donation,
                              sent_date: Time.local(2015, 03, 22)
                             )

      FactoryGirl.create(:transaction, donation: weekly_failed_donation, created_at: Time.local(2015, 03, 29))

      Timecop.travel(Time.local(2015, 03, 22))
      fire_trigger_and_check_no_flagging

      Timecop.travel(Time.local(2015, 04, 22))
      fire_trigger_and_check_no_flagging

      Timecop.travel(Time.local(2015, 05, 22))
      fire_trigger_and_check_no_flagging
    end

    it "should NOT flag donation when they don't receive an email" do
      Timecop.travel(Time.local(2015, 03, 22))
      fire_trigger_and_check_no_flagging

      Timecop.travel(Time.local(2015, 04, 22))
      fire_trigger_and_check_no_flagging

      Timecop.travel(Time.local(2015, 05, 22))
      fire_trigger_and_check_no_flagging
    end
  end

  describe '#cancel' do
    context 'with a recurring donation that last failed two months agao' do
      let!(:donation){ create(:recurring_donation, active: true, last_donated_at: 5.months.ago, last_tried_at: 4.months.ago) }
      before do
        DonationTriggerService.new.fire_trigger
        donation.reload
      end

      specify do
        expect(donation.active).to eq(false)
        expect(donation.cancel_reason).to eq('automatic')
        expect(donation.cancelled_at.to_date).to eq((donation.last_donated_at + 3.months).to_date)
      end
    end

    context 'with a recurring donation that last failed less than two months ago' do
      let!(:donation){ create(:recurring_donation, active: true, last_donated_at: 4.months.ago, last_tried_at: 2.months.ago) }
      before do
        DonationTriggerService.new.fire_trigger
        donation.reload
      end

      specify{ expect(donation.active).to eq(true) }
    end
  end

  private

  def fire_trigger_and_check_no_flagging
    DonationTriggerService.new.fire_trigger
    [weekly_failed_donation, monthly_failed_donation, annual_failed_donation].each { |donation| donation.reload }
    [weekly_failed_donation, monthly_failed_donation, annual_failed_donation].each { |donation| donation.flagged_because.should be_nil }
    [weekly_failed_donation, monthly_failed_donation, annual_failed_donation].each { |donation| donation.dismissed_at.should be_nil }
  end

  def fire_trigger_and_check_flagged_because_on_donations_is(reason)
    DonationTriggerService.new.fire_trigger
    [weekly_failed_donation, monthly_failed_donation, annual_failed_donation].each { |donation| donation.reload }
    [weekly_failed_donation, monthly_failed_donation, annual_failed_donation].each { |donation| donation.flagged_because.should == reason }
    [weekly_failed_donation, monthly_failed_donation, annual_failed_donation].each { |donation| donation.dismissed_at.should be_nil }
  end

  def fire_trigger_and_check_flagged_since_on_donations_is(time)
    DonationTriggerService.new.fire_trigger
    [weekly_failed_donation, monthly_failed_donation, annual_failed_donation].each { |donation| donation.reload }
    [weekly_failed_donation, monthly_failed_donation, annual_failed_donation].each { |donation| donation.flagged_since.should == time }
    [weekly_failed_donation, monthly_failed_donation, annual_failed_donation].each { |donation| donation.dismissed_at.should be_nil }
  end
end
