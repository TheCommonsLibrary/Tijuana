require File.dirname(__FILE__) + '/../spec_helper.rb'
require File.dirname(__FILE__) + '/../models/recording_gateway.rb'

describe DonationService do
  before(:each) { @service = DonationService.new }

  def create_and_configure_donation(frequency, post_process_attrs)
    donation = create(:donation, :frequency => frequency)
    @service.process!(donation)
    donation.update_attributes!(post_process_attrs)
    donation
  end

  describe "#refund" do
    before(:each) do
      ActionMailer::Base.deliveries = []
      @service = DonationService.new
      @donation = create(:donation, :amount_in_cents => 2500)
      @service.process!(@donation)
      ActionMailer::Base.should have(1).deliveries
      @transaction = @donation.transactions.last
    end

    it "should refund the full amount and send a receipt with the same amount" do
      @service.refund(@transaction.amount_in_cents, @transaction)
      @donation.transactions.count.should eql(2)
      @transaction.should be_refunded

      refund_transaction = @transaction.refunded_by
      refund_transaction.should be_refund
      refund_transaction.message.should eql("Bogus Gateway: Approved Refund")
      refund_transaction.amount_in_cents.should == -2500
      ActionMailer::Base.should have(2).deliveries
      ActionMailer::Base.deliveries[1].to_s.should match(/Refund: \$25.00 AUD/)
    end

    it "should refund a partial amount and send a receipt with the same amount" do
      @service.refund(500, @transaction)
      @donation.transactions.count.should eql(2)
      @transaction.should be_refunded

      refund_transaction = @transaction.refunded_by
      refund_transaction.should be_refund
      refund_transaction.message.should eql("Bogus Gateway: Approved Refund")
      refund_transaction.amount_in_cents.should == -500
      ActionMailer::Base.should have(2).deliveries
      ActionMailer::Base.deliveries[1].to_s.should match(/Refund: \$5.00 AUD/)
    end

    it "should not refund more than the original amount" do
      expect { @service.refund(@transaction.amount_in_cents + 1, @transaction) }.to raise_error(Transaction::RefundFailedError)
      @donation.transactions.count.should eql(1)
      @transaction.should_not be_refunded
      ActionMailer::Base.should have(1).deliveries
    end

    it "should record an attempted transaction but not mark as refunded on gateway failure" do
      expect { @service.refund(ActiveMerchant::Billing::BogusGateway::MAGIC_CENTS_TO_FORCE_FAILURE, @transaction) }.to raise_error(Transaction::RefundFailedError)
      @donation.transactions.count.should eql(2)
      @transaction.should_not be_refunded
      @donation.transactions.last.message.should == "Bogus Gateway: Failed Refund"
      ActionMailer::Base.should have(1).deliveries
    end

    it "should not refund a failed transaction" do
      @transaction.update_attributes!(:successful => false)
      expect { @service.refund(@transaction.amount_in_cents, @transaction) }.to raise_error(Transaction::RefundFailedError)
      ActionMailer::Base.should have(1).deliveries
    end

    it "should not refund a transaction twice" do
      @service.refund(100, @transaction)
      expect { @service.refund(100, @transaction) }.to raise_error(Transaction::RefundFailedError)
      ActionMailer::Base.should have(2).deliveries
    end
  end


  describe "processing" do
    it "returns false if validation fails" do
      donation = build(:donation)
      donation.card_number = ""
      @service.process!(donation).should be false
    end

    context "fraudulent IP" do
      it "should reject transaction from a blocked IP" do
        BlockedIp.create!(ip_address: '111.12.34.2')
        donation = build(:donation)
        ExceptionNotifier::Notifier.should_not_receive(:background_exception_notification)

        @service.setup_recurring_donation(donation, ip: '111.12.34.2').should be false
        @service.make_one_off_donation(donation, ip: '111.12.34.2').should be false
      end
    end

    describe "one-off credit card payments" do
      before do
        ActionMailer::Base.deliveries = []
        UserMailer.stub(:welcome_to_getup_email) { double(:deliver => nil) }
      end

      before(:each) do
        @now = Time.now
        Time.stub(:now).and_return(@now)
      end

      it "makes a purchase, create trigger and records a transaction" do
        UserActivityEvent.should_receive(:action_taken!)
        donation = create(:donation, :card_number => PaymentGateways::CARD_SUCCESS)
        donation.trigger_id.should be_nil
        @service.process!(donation).should be true
        donation.reload

        donation.trigger_id.should_not be_nil
        donation.last_donated_at.utc.to_s.should == @now.utc.to_s
        donation.transactions.count.should == 1
        txn = donation.transactions.first
        txn.amount_in_cents.should == donation.amount_in_cents
        txn.should be_successful
        ActionMailer::Base.should have(1).deliveries
      end

      it 'creates a shared connection' do
        uae = double
        UserActivityEvent.stub(:action_taken!).and_return(uae)
        shared_connection = double
        shared_connection.stub(:valid?).and_return(true)
        shared_connection.should_receive(:user_activity_event=).with(uae)
        shared_connection.should_receive(:save!)
        donation = create(:donation, :card_number => PaymentGateways::CARD_SUCCESS)
        donation.trigger_id.should be_nil
        @service.process!(donation, {:shared_connection => shared_connection}).should be true
      end

      it 'does not create a shared connection' do
        uae = double
        UserActivityEvent.stub(:action_taken!).and_return(uae)
        shared_connection = double
        shared_connection.stub(:valid?).and_return(true)
        shared_connection.should_not_receive(:user_activity_event=)
        shared_connection.should_not_receive(:save)
        donation = create(:donation, :card_number => PaymentGateways::CARD_FAILURE)
        donation.trigger_id.should be_nil
        @service.process!(donation, {:shared_connection => shared_connection}).should be false
      end

      it 'should set the acquisition source on the created user activity event' do
        acquisition_source = create(:acquisition_source)
        donation = create(:donation, :card_number => PaymentGateways::CARD_SUCCESS)
        @service.process!(donation, {acquisition_source: acquisition_source}).should be true
        expect(donation.user.user_activity_events.actions_taken.last.acquisition_source).to eq(acquisition_source)
      end

      it "fails to make a purchase and adds an error and does not create a trigger" do
        UserActivityEvent.should_not_receive(:action_taken!)
        donation = create(:donation, :card_number => PaymentGateways::CARD_FAILURE)
        donation.trigger_id.should be_nil
        @service.process!(donation).should be false
        donation.reload

        donation.trigger_id.should be_nil
        donation.errors[:credit_card].first.should match "payment failed"
        donation.last_donated_at.should be_nil
        donation.last_tried_at.should_not be_nil

        donation.transactions.count.should == 1
        txn = donation.transactions.first
        txn.amount_in_cents.should == donation.amount_in_cents
        txn.should_not be_successful
        ActionMailer::Base.should have(0).deliveries
      end

      it "should filter out donations from blocked IPs" do
        UserActivityEvent.should_not_receive(:action_taken!)
        donation = create(:donation, :card_number => PaymentGateways::CARD_SUCCESS)
        BlockedIp.stub(:find_by_ip_address).and_return(BlockedIp.new(ip_address: '1.1.1.1'))
        @service.process!(donation, {ip: '1.1.1.1'}).should be false
        Transaction.first.message.should == 'external payment error'
      end

      context "cc_logging enabled" do
        before :each do
          Setting[:use_cc_logging] = 'true'
        end

        context "with an unsuccessful gateway response" do
          let(:donation) { create(:donation, :card_number => PaymentGateways::CARD_FAILURE) }

          it "should log credit card details" do
            @service.process!(donation)
            failed_donation = FailedDonation.first
            failed_donation.donation_id.should == donation.id
            failed_donation.credit_card.should include(donation.card_number)
          end

          it "should not record a user activity event" do
            UserActivityEvent.should_not_receive(:action_taken!)
            @service.process!(donation)
          end
        end

        context "with gateway raising exception" do
          let(:donation) { create(:donation, :card_number => '1111222233334444', :amount_in_cents => ActiveMerchant::Billing::BogusGateway::MAGIC_CENTS_TO_FORCE_EXCEPTION) }

          it "should log credit card details" do
            expect {@service.process!(donation)}.to raise_error('FORCED EXCEPTION FOR TEST')
            failed_donation = FailedDonation.first
            failed_donation.donation_id.should == donation.id
            failed_donation.credit_card.should include('1111222233334444')
          end

          it "should not record a user activity eventy" do
            UserActivityEvent.should_not_receive(:action_taken!)
            expect {@service.process!(donation)}.to raise_error('FORCED EXCEPTION FOR TEST')
          end
        end

        context "with the gateway returning a successful response" do
          let(:donation) { create(:donation, :card_number => PaymentGateways::CARD_SUCCESS) }

          it "should not log credit card details" do
            @service.process!(donation)
            FailedDonation.all.should be_empty
          end

          it "should record a user activity eventy" do
            UserActivityEvent.should_receive(:action_taken!)
            @service.process!(donation)
          end
        end
      end

      context "cc_logging disabled" do
        let(:donation) { create(:donation, :card_number => PaymentGateways::CARD_FAILURE) }

        before do
          Setting[:use_cc_logging] = nil
          Setting[:use_fraud_guard] = nil
        end

        it "should not create any events" do
          UserActivityEvent.should_not_receive(:action_taken!)
          @service.process! donation
        end

        it "should not log credit card data when transaction fails" do
          @service.process! donation
          FailedDonation.all.should be_empty
        end
      end
    end

    describe "quick donation" do

      let :success_response do ActiveMerchant::Billing::Response.new(true, "Like success, man") end

      before :each do
        Timecop.travel '25 Dec 2014' # freeze so credit card not expired
        @user_with_quick_donate_trigger = create(:user, quick_donate_trigger_id: 'USER_TRIGGER_ID')
        @original_donation = create(:donation, user: @user_with_quick_donate_trigger, trigger_id: 'USER_TRIGGER_ID', payment_method: 'credit_card', card_number: '4444444444444448', card_expiry_month: '12', card_expiry_year: '14', name_on_card: 'Original Name')
      end

      after :each do
        Timecop.return
      end

      context "non recurring" do

        let :quick_donation do create(:donation, user: @user_with_quick_donate_trigger, quick_donation: '1') end

        it "should perform triggered payment using user's quick_donate_trigger_id" do
          UserActivityEvent.should_receive(:action_taken!)
          @service.process!(quick_donation)
          quick_donation.trigger_id.should == "USER_TRIGGER_ID"
        end

        it "should copy credit card details onto quick donation" do
          UserActivityEvent.should_receive(:action_taken!)
          quick_donation.should_receive(:copy_credit_card_details!).with(@original_donation)
          @service.process!(quick_donation)
        end

        it "should create transaction record" do
          UserActivityEvent.should_receive(:action_taken!)
          @service.process!(quick_donation)
          quick_donation.transactions.size.should == 1
          transaction = quick_donation.transactions.first
          transaction.amount_in_cents.should == quick_donation.amount_in_cents
          transaction.invoiced.should be true
          transaction.should be_successful
        end
      end

      context "recurring" do

        let :quick_donation do create(:donation, :frequency => "monthly", quick_donation: '1', user: @user_with_quick_donate_trigger) end

        it "should use quickdonate trigger for recurring donation" do
          UserActivityEvent.should_receive(:action_taken!)
          GatewaySwitcher.should_not_receive(:store)
          @service.process!(quick_donation)
          quick_donation.trigger_id.should == 'USER_TRIGGER_ID'
        end

        it "should update donation's last donated at to be now" do
          Timecop.freeze do
            @service.process!(quick_donation)
            quick_donation.last_donated_at.should == Time.now
          end
        end
      end

    end
  end

  describe "recurring credit card payments" do

    before do
      ActionMailer::Base.deliveries = []
      UserMailer.stub(:welcome_to_getup_email) { double(:deliver => nil) }
    end

    it "receipt should be sent only for the first transaction" do
      donation = create(:donation, :card_number => PaymentGateways::CARD_SUCCESS, :frequency => "weekly")
      @service.process!(donation).should be true
      ActionMailer::Base.should have(1).deliveries
      @service.trigger_recurring_payment!(donation)
      ActionMailer::Base.should have(1).deliveries
      donation.last_tried_at = nil
      @service.trigger_recurring_payment!(donation)
      ActionMailer::Base.should have(1).deliveries
    end

    context "with an failing credit card" do
      it "should record a transaction, add an error and delete the trigger" do
        UserActivityEvent.should_not_receive(:action_taken!)
        donation = create(:donation, :card_number => PaymentGateways::CARD_FAILURE, :frequency => "monthly")

        @service.process!(donation).should be false
        donation.errors[:credit_card].first.should match "payment failed"
        donation.last_donated_at.should be_nil
        donation.last_tried_at.should_not be_nil

        donation.should have(1).transactions
        txn = donation.transactions.first
        txn.amount_in_cents.should == donation.amount_in_cents
        txn.should_not be_successful

        donation.active.should == true

        ActionMailer::Base.should have(0).deliveries
      end
    end

    it "triggers another payment on request" do
      Timecop.freeze(Time.now)
      UserActivityEvent.should_receive(:action_taken!).twice
      donation = create(:donation, :card_number => PaymentGateways::CARD_SUCCESS, :frequency => "monthly")

      @service.process!(donation).should be true
      donation.last_donated_at.should == Time.now
      donation.should have(1).transactions

      future_time = Time.now + 1.hour
      Timecop.travel(future_time) do
        @service.trigger_recurring_payment!(donation).should be true
        donation.last_donated_at.utc.to_s.should == future_time.utc.to_s
        donation.reload.should have(2).transactions
      end
    end

    it "triggers any periodic donations that are due in the specified window" do
      Timecop.freeze(Time.now)
      UserActivityEvent.should_receive(:action_taken!).exactly(8).times
      weekly_overdue = create_and_configure_donation("weekly", :last_donated_at => 8.days.ago)
      weekly_due_in_the_next_hour = create_and_configure_donation("weekly", :last_donated_at => 10021.minutes.ago) # 10080 minutes = 1 week
      weekly_almost_due_in_the_next_hour = create_and_configure_donation("weekly", :last_donated_at => 10019.minutes.ago) # 10080 minutes = 1 week
      weekly_not_due = create_and_configure_donation("weekly", :last_donated_at => 2.days.ago)
      weekly_overdue_inactive = create_and_configure_donation("weekly", :active => false, :last_donated_at => 8.days.ago)
      monthly_overdue = create_and_configure_donation("monthly", :last_donated_at => 6.months.ago)

      @service.trigger_due_periodic_payments!("weekly", (24*7).hours.ago, 1.hour)

      weekly_overdue.reload.should have(2).transactions
      weekly_due_in_the_next_hour.reload.should have(2).transactions
      weekly_almost_due_in_the_next_hour.reload.should have(1).transactions
      weekly_not_due.reload.should have(1).transactions
      weekly_overdue_inactive.reload.should have(1).transactions
      monthly_overdue.reload.should have(1).transactions
    end

    context "with an overdue donation" do
      let(:frequency) { "weekly" }
      let(:donation) { create(:recurring_donation, frequency: frequency, last_donated_at: 10.days.ago, last_tried_at: Date.today) }
      let!(:transaction) { create(:transaction, donation: donation) }

      let(:last_donated_before) { Time.now - (24*7).hours }
      let(:becoming_due_in_the_next) { 1.hour }
      let(:trigger_overdue) { DonationService.new.trigger_due_periodic_payments!(frequency, last_donated_before, becoming_due_in_the_next) }

      context "after 3 days" do
        before { Timecop.travel 3.days.from_now }
        it "retries" do
          expect{ trigger_overdue }.to change{ donation.transactions.size }.by(1)
        end

        context "with successful donation within the period" do
          before do
            donation.last_donated_at = 3.days.ago
            donation.last_tried_at = 10.days.ago
            donation.save
          end

          it "does not retry" do
            expect{ trigger_overdue }.to_not change{ donation.transactions.size }
          end
        end
      end

      context "when last tried on day 3" do
        before do
          donation.last_tried_at = 3.days.from_now
          donation.save
        end
        context "after 5 days" do
          before { Timecop.travel 5.days.from_now }
          it "waits patiently" do
            expect{ trigger_overdue }.to_not change{ donation.transactions.size }
          end
        end

        context "after 6 days" do
          before { Timecop.travel 6.days.from_now }
          it "tries again" do
            expect{ trigger_overdue }.to change{ donation.transactions.size }.by(1)
          end
        end
      end

      context "after 36 days after the due date" do
        before { Timecop.travel(donation.last_donated_at + 7.days + 37.days) }
        it "acquiesces" do
          expect{ trigger_overdue }.to_not change{ donation.transactions.size }
        end
      end

      context "with overdue annual donation" do
        let(:frequency){ 'annual' }
        let(:last_donated_before) { Time.now - 1.year }
        before{ donation.update_attributes!(last_donated_at: 370.days.ago, last_tried_at: nil) }

        it "should retry" do
          expect{ trigger_overdue }.to change{ donation.transactions.size }
        end

        context "after 36 day after the due date" do
          before { Timecop.travel 37.days }
          it "acquiesces" do
            expect{ trigger_overdue }.to_not change{ donation.transactions.size }
          end
        end
      end

      after { Timecop.return }
    end

    context "future payments" do
      let(:donation_module) {create(:donation_module, commence_donation_at: Date.parse('2012-05-30'))}
      let(:donation) { create(:donation, frequency: 'weekly', content_module: donation_module)}

      it "should create a trigger but not trigger it until the due date" do
        GatewaySwitcher.gateway1_mapper.stub(:gateway).and_return(@recording_gateway = RecordingGateway.new)
        Timecop.travel(Date.parse('2012-04-30')) { @service.process!(donation) }

        donation.trigger_id.should_not be_empty
        @recording_gateway.purchased.should be false
        @recording_gateway.stored.should be true
        donation.last_donated_at.utc.to_s.should == Time.local(2012, 5, 23).utc.to_s # 1 week before commence date
      end

      it "should trigger donation at/after commence date" do
        GatewaySwitcher.gateway1_mapper.stub(:gateway).and_return(@recording_gateway = RecordingGateway.new)
        Timecop.travel(Date.parse('2012-04-30')) { @service.process!(donation) }
        Timecop.travel(Date.parse('2012-06-15')) do
          @service.trigger_due_periodic_payments! "weekly", Time.now - (24*7).hours, 1.hour
        end

        @recording_gateway.purchased.should be true
      end

      context "quick donate" do
        let!(:prev_quick_donation) { create(:donation, trigger_id: '9') }
        let(:quick_donate_user) { create(:user, quick_donate_trigger_id: '9') }
        let(:quick_donation) { create(:donation, frequency: 'weekly', content_module: donation_module, quick_donation: true, user: quick_donate_user)}

        it "should record the trigger but not trigger it until the due date" do
          GatewaySwitcher.gateway1_mapper.stub(:gateway).and_return(@recording_gateway = RecordingGateway.new)
          Timecop.travel(Date.parse('2012-04-30')) { @service.process!(quick_donation) }

          quick_donation.trigger_id.should eq '9'
          @recording_gateway.purchased.should be false
          quick_donation.last_donated_at.utc.to_s.should == Time.local(2012, 5, 23).utc.to_s # 1 week before commence date
        end

        it "should trigger quick donation at/after commence date" do
          GatewaySwitcher.gateway1_mapper.stub(:gateway).and_return(@recording_gateway = RecordingGateway.new)
          Timecop.travel(Date.parse('2012-04-30')) { @service.process!(donation) }
          Timecop.travel(Date.parse('2012-06-15')) do
            @service.trigger_due_periodic_payments! "weekly", Time.now - (24*7).hours, 1.hour
          end
          @recording_gateway.purchased.should be true
        end
      end
    end

    describe 'periodic_donations_processed_before' do
      context 'with overdue donations' do
        before :each do
          @annual_overdue = create_and_configure_donation("annual", :last_donated_at => (1.year + 1.minute).ago)
          @monthly_overdue = create_and_configure_donation("monthly", :last_donated_at => (1.month + 1.minute).ago)
          @weekly_overdue = create_and_configure_donation("weekly", :last_donated_at => (7.days + 1.minute).ago)
          @weekly_not_due = create_and_configure_donation("weekly", :last_donated_at => 6.days.ago)
        end

        it "should find overdue donation by period" do
          overdue_donations = Donation.periodic_donations_processed_before "weekly", 7.days.ago
          overdue_donations.count.should == 1
          overdue_donations.first.should == @weekly_overdue
        end
      end
    end

    describe '#some_of_the_periodic_donations_overdue_by' do
      it "should find overdue donations" do
        UserActivityEvent.should_receive(:action_taken!).twice
        create_and_configure_donation("weekly", :last_donated_at => 7.days.ago)
        periodic_overdue = create_and_configure_donation("weekly", :last_donated_at => (7.days + 5.minutes).ago)
        overdue_donations = Donation.some_of_the_periodic_donations_overdue_by 3.minutes
        overdue_donations.count.should == 1
        overdue_donations.first.should == periodic_overdue
      end
    end

    describe "trigger_overdue_periodic_payment!" do
      without_transactional_fixtures do
        it "should not process periodic donation multiple times if processed by multiple threads" do
          UserActivityEvent.should_receive(:action_taken!).twice
          weekly_overdue = create_and_configure_donation("weekly", :last_donated_at => 8.days.ago)
          GatewaySwitcher.stub(:find_gateway_mapper).and_return GatewaySwitcher.gateway1_mapper
          GatewaySwitcher.should_receive(:purchase_with_trigger).with(weekly_overdue, {order_id: weekly_overdue.id}){
            sleep(3)
            ActiveMerchant::Billing::Response.new(true, "success")
          }
          @service_copy = DonationService.new
          weekly_overdue_copy = Donation.find(weekly_overdue.id)

          donation_thread = Thread.new do
            Donation.transaction do
              expect {
                @service_copy.trigger_overdue_periodic_payment!(weekly_overdue_copy)
              }.to raise_error Donation::PeriodicDonationError, "Could not claim donation id #{weekly_overdue_copy.id} for periodic payment processing - are you sure there are not two concurrent cron jobs running?"
            end
          end

          @service.trigger_overdue_periodic_payment!(weekly_overdue)
          donation_thread.join
          Transaction.count.should == 2 # includes one for the original recurring transaction creation
        end

        it "should update last_donated_at if payment is successful" do
          UserActivityEvent.should_receive(:action_taken!).twice
          weekly_overdue = create_and_configure_donation("weekly", :last_donated_at => 8.days.ago)

          Timecop.freeze do
            donation_triggered_at = Time.now
            @service.trigger_overdue_periodic_payment!(weekly_overdue)
            weekly_overdue.reload
            weekly_overdue.last_donated_at.utc.to_s.should == donation_triggered_at.utc.to_s
          end
        end

        it "should update last_tried_at but not update last_donated_at if payment is not successful" do
          UserActivityEvent.should_receive(:action_taken!)
          weekly_overdue = create_and_configure_donation("weekly", :last_donated_at => 9.days.ago, :last_tried_at => 8.days.ago, :amount_in_cents => ActiveMerchant::Billing::BogusGateway::MAGIC_CENTS_TO_FORCE_FAILURE)
          original_last_donated_at = weekly_overdue.last_donated_at

          Timecop.freeze do
            @service.trigger_overdue_periodic_payment!(weekly_overdue)
            weekly_overdue.reload
            weekly_overdue.last_donated_at.to_s.should == original_last_donated_at.to_s
            weekly_overdue.last_tried_at.utc.to_s.should == Time.now.utc.to_s
          end
        end

        it "should raise error and not update last_donated_at or last_tried_at if payment gateway raises exception" do
          UserActivityEvent.should_receive(:action_taken!)
          weekly_overdue = create_and_configure_donation("weekly", :last_donated_at => 9.days.ago, :last_tried_at => 8.days.ago, :amount_in_cents => ActiveMerchant::Billing::BogusGateway::MAGIC_CENTS_TO_FORCE_EXCEPTION)
          original_last_donated_at = weekly_overdue.last_donated_at
          original_last_tried_at = weekly_overdue.last_tried_at

          expect {
            @service.trigger_overdue_periodic_payment!(weekly_overdue)
          }.to raise_error(ActiveMerchant::ConnectionError, /FORCED EXCEPTION/)

          weekly_overdue.reload
          weekly_overdue.last_donated_at.to_s.should == original_last_donated_at.to_s
          weekly_overdue.last_tried_at.to_s.should == original_last_tried_at.to_s
        end
      end
    end


    it "should filter out recurring donations from blocked IPs" do
      UserActivityEvent.should_not_receive(:action_taken!)
      donation = create(:donation, :card_number => PaymentGateways::CARD_SUCCESS, :frequency => "weekly")
      BlockedIp.stub(:find_by_ip_address).and_return(BlockedIp.new(ip_address: '1.1.1.1'))
      @service.process!(donation, {:ip => '1.1.1.1'})
      @service.should_not_receive(:issue_one_off_donation)
      Transaction.first.message.should == 'external payment error'
      donation.active.should == false
    end

    it "should process the transaction and reset cancelled fields" do
      donation = create(:donation, :id => 1111, :card_number => PaymentGateways::CARD_SUCCESS, :frequency => "weekly", :active => 0, cancelled_at: Time.now, cancel_reason: 'auto')
      expect(@service.update_recurring_trigger!(donation, {card_cvv: 321}))
      donation.reload
      expect(donation).to be_active
      expect(donation.cancelled_at).to be_nil
      expect(donation.cancel_reason).to be_nil
    end
  end

  describe "updating a recurring donation" do
    before(:each) do
      @donation = create(:donation, :card_number => PaymentGateways::CARD_SUCCESS, :frequency => "monthly")
      @service.process!(@donation)
      @donation = Donation.find(@donation.id)
    end
    let!(:successful_card_details) do
      {
          card_number: PaymentGateways::CARD_SUCCESS,
          card_cvv: 667,
          card_expiry_month: 2,
          card_expiry_year: 2050,
          name_on_card: 'iama newguy',
          amount_in_dollars: 10000.0,
          frequency: "weekly"
      }
    end

    it "should create a new trigger and update donation attributes" do
      new_trigger_id = nil
      Timecop.freeze(Time.parse("Feb 14 2038")) do
        new_trigger_id = "#{@donation.id}_#{Time.now.to_i}"
        @service.update_recurring_trigger!(@donation, successful_card_details).should be true
      end

      @donation.trigger_id.should == new_trigger_id
      @donation.card_number.should eql successful_card_details[:card_number]
      @donation.card_cvv.should eql successful_card_details[:card_cvv]
      @donation.card_expiry_month.should eql successful_card_details[:card_expiry_month]
      @donation.card_expiry_year.should eql 2050
      @donation.name_on_card.should eql successful_card_details[:name_on_card]
      @donation.amount_in_dollars.should eql successful_card_details[:amount_in_dollars]
      @donation.frequency.should eql successful_card_details[:frequency]
      @donation.card_type.should be_nil
      @donation.flagged_since.should be_nil
      @donation.flagged_because.should be_nil
      @donation.assigned_to.should be_nil
      @donation.assigned_date.should be_nil
    end

    context "donation saved for user's quick donate" do
      before(:each) do
        user = @donation.user
        user.quick_donate_trigger_id = @donation.trigger_id
        user.save!
      end

      it "should update the user's quick donate trigger" do
        new_trigger_id = nil
        attrs = {
            card_number: PaymentGateways::CARD_SUCCESS,
            card_cvv: 666,
            card_expiry_month: 2,
            card_expiry_year: 2050,
            name_on_card: 'iama newguy',
            amount_in_dollars: 10000.0,
            frequency: "weekly"
        }

        Timecop.freeze(Time.parse("Feb 14 2038")) do
          new_trigger_id = "#{@donation.id}_#{Time.now.to_i}"
          @service.update_recurring_trigger!(@donation, attrs).should be true
        end

        @donation.reload
        user = User.find(@donation.user_id)
        user.quick_donate_trigger_id.should == new_trigger_id
        user.quick_donate_trigger_id.should == @donation.trigger_id
      end
    end

    it "should trigger payment if the previous transaction failed" do
      UserActivityEvent.should_receive(:action_taken!)
      failed_donation = create(:donation, :card_number => PaymentGateways::CARD_FAILURE, :frequency => "monthly")
      @service.process!(failed_donation)

      a_distant_future = Time.parse("Feb 14 2038")
      Time.stub(:now).and_return(a_distant_future)
      attrs = {
          card_number: PaymentGateways::CARD_SUCCESS,
          card_cvv: 666,
          card_expiry_month: 2,
          card_expiry_year: 2050,
          name_on_card: 'iama newguy',
          amount_in_dollars: 10000.0,
          frequency: "weekly"
      }

      @service.update_recurring_trigger!(failed_donation, attrs).should be true
      new_trigger_id = "#{failed_donation.id}_#{a_distant_future.to_i}"
      failed_donation.trigger_id.should == new_trigger_id
      failed_donation.card_number.should eql attrs[:card_number]
      failed_donation.card_cvv.should eql attrs[:card_cvv]
      failed_donation.card_expiry_month.should eql attrs[:card_expiry_month]
      failed_donation.card_expiry_year.should eql 2050
      failed_donation.name_on_card.should eql attrs[:name_on_card]
      failed_donation.amount_in_dollars.should eql attrs[:amount_in_dollars]
      failed_donation.frequency.should eql attrs[:frequency]
      failed_donation.card_type.should be_nil
      failed_donation.flagged_since.should be_nil
      failed_donation.flagged_because.should be_nil
      failed_donation.assigned_to.should be_nil
      failed_donation.assigned_date.should be_nil
    end

    it "should not persist changes if updating trigger failed" do
      old_trigger_id = @donation.trigger_id
      old_card_number = @donation.card_number
      old_card_cvv = @donation.card_cvv
      old_card_expiry_month = @donation.card_expiry_month
      old_card_expiry_year = @donation.card_expiry_year
      old_amount_in_dollars = @donation.amount_in_dollars
      old_frequency = @donation.frequency
      old_name_on_card = @donation.name_on_card
      old_card_type = @donation.card_type

      attrs = {
          card_cvv: 666,
          card_expiry_month: 2,
          card_expiry_year: 50,
          card_type: "visa",
          name_on_card: 'adifferent nameforthisguy',
          amount_in_cents: 10000,
          frequency: "weekly",
          card_number: PaymentGateways::CARD_FAILURE
      }
      @service.update_recurring_trigger!(@donation,attrs).should be false

      saved_donation = Donation.find(@donation.id)
      saved_donation.trigger_id.should eql old_trigger_id
      saved_donation.card_number.should eql old_card_number
      saved_donation.card_cvv.should eql old_card_cvv
      saved_donation.card_expiry_month.should eql old_card_expiry_month
      saved_donation.card_expiry_year.should eql old_card_expiry_year
      saved_donation.name_on_card.should eql old_name_on_card
      saved_donation.amount_in_dollars.should eql old_amount_in_dollars
      saved_donation.frequency.should eql old_frequency
      saved_donation.card_type.should eql old_card_type

      @donation.errors[:credit_card][0].should match("payment failed - Bogus Gateway: Forced failure")
    end

    it "should clear last_tried_at when adding trigger succeeds" do
      attrs = {
          card_cvv: 666,
          card_expiry_month: 2,
          card_expiry_year: 50,
          card_type: "visa",
          amount_in_dollars: 10000.0,
          frequency: "weekly",
          card_number: PaymentGateways::CARD_SUCCESS
      }

      @donation.last_tried_at= 1.year.ago
      @donation.save!
      @donation = Donation.find(@donation.id)
      @donation.stub(:payment_gateway).and_return(@recording_gateway = RecordingGateway.new)
      @service.update_recurring_trigger!(@donation, attrs).should be true

      @donation = Donation.find(@donation.id)
      @donation.last_tried_at.should be_nil
    end

    it "should update donation attributes without adding another trigger" do
      attrs = {
          frequency: "weekly",
          name_on_card: 'adifferent personhere'
      }
      old_trigger_id = @donation.trigger_id
      old_amount_in_cents = @donation.amount_in_cents
      @service.should_not_receive(:trigger_recurring_payment!)
      @service.update_recurring_trigger!(@donation,attrs).should be true
      @donation.trigger_id.should eql old_trigger_id
      @donation.amount_in_cents.should eql old_amount_in_cents
      @donation.name_on_card.should eql attrs[:name_on_card]
      @donation.frequency.should eql attrs[:frequency]
    end

    it "should NOT update trigger if credit card values are the same" do
      old_trigger_id = @donation.trigger_id
      existing_attrs = {
          card_number: @donation.card_number,
          card_cvv: nil,
          card_expiry_month: @donation.card_expiry_month,
          card_expiry_year: @donation.card_expiry_year,
          amount_in_dollars: @donation.amount_in_dollars,
          frequency: @donation.frequency
      }
      @donation.stub(:update_attributes!)
      @donation.should_not_receive(:update_attributes!)
      @service.should_not_receive(:trigger_recurring_payment!)
      @service.update_recurring_trigger!(@donation,existing_attrs).should be false
      @donation.trigger_id.should eql old_trigger_id
    end
  end

  describe "handling dismissed donations" do

    before(:each) do
    end

    it "should unflag the flagged donations if the transaction is successful" do
      UserActivityEvent.should_receive(:action_taken!)
      flagged_donation_success = create(:donation, :frequency => "weekly", :last_donated_at => 1.month.ago, :last_tried_at => 8.days.ago, :flagged_since => Time.now, :flagged_because => Time.now, :assigned_to => Time.now, :assigned_date => Time.now, :dismissed_at => Time.now)
      flagged_donation_fail = create(:donation, :card_number => PaymentGateways::CARD_FAILURE, :frequency => "weekly", :flagged_since => Time.now, :flagged_because => Time.now, :assigned_to => Time.now, :assigned_date => Time.now, :dismissed_at => Time.now)

      @service.process!(flagged_donation_success)
      @service.process!(flagged_donation_fail)

      flagged_donation_success.reload
      flagged_donation_success.flagged_since.should be_nil
      flagged_donation_success.flagged_because.should be_nil
      flagged_donation_success.dismissed_at.should be_nil
      flagged_donation_success.assigned_to.should be_nil
      flagged_donation_success.assigned_date.should be_nil

      flagged_donation_fail.reload
      flagged_donation_fail.flagged_since.should_not be_nil
      flagged_donation_fail.flagged_because.should_not be_nil
      flagged_donation_fail.dismissed_at.should be_nil
      flagged_donation_fail.assigned_to.should_not be_nil
      flagged_donation_fail.assigned_date.should_not be_nil
    end

    it "should not unflag expiring credit card flagged donations if the transaction is successful" do
      UserActivityEvent.should_receive(:action_taken!).exactly(3).times
      expired_flagged_suc_tran = create(:donation, :frequency => "weekly", :last_donated_at => 1.month.ago, :last_tried_at => 8.days.ago, :flagged_since => Time.now, :flagged_because => 'Expired Credit Card', :assigned_to => Time.now, :assigned_date => Time.now, :dismissed_at => Time.now)
      expiring_flagged_suc_tran = create(:donation, :frequency => "weekly", :last_donated_at => 1.month.ago, :last_tried_at => 8.days.ago, :flagged_since => Time.now, :flagged_because => 'Expiring Credit Card', :assigned_to => Time.now, :assigned_date => Time.now, :dismissed_at => Time.now)
      over_two_flagged_suc_tran = create(:donation, :frequency => "weekly", :last_donated_at => 1.month.ago, :last_tried_at => 8.days.ago, :flagged_since => Time.now, :flagged_because => 'Two or more consecutive failures', :assigned_to => Time.now, :assigned_date => Time.now, :dismissed_at => Time.now)

      @service.process!(expiring_flagged_suc_tran)
      expiring_flagged_suc_tran.reload
      expiring_flagged_suc_tran.flagged_since.should_not be_nil
      expiring_flagged_suc_tran.flagged_because.should_not be_nil
      expiring_flagged_suc_tran.dismissed_at.should_not be_nil
      expiring_flagged_suc_tran.assigned_to.should_not be_nil
      expiring_flagged_suc_tran.assigned_date.should_not be_nil

      @service.process!(expired_flagged_suc_tran)
      expired_flagged_suc_tran.reload
      expired_flagged_suc_tran.flagged_since.should be_nil
      expired_flagged_suc_tran.flagged_because.should be_nil
      expired_flagged_suc_tran.dismissed_at.should be_nil
      expired_flagged_suc_tran.assigned_to.should be_nil
      expired_flagged_suc_tran.assigned_date.should be_nil

      @service.process!(over_two_flagged_suc_tran)
      over_two_flagged_suc_tran.reload
      over_two_flagged_suc_tran.flagged_since.should be_nil
      over_two_flagged_suc_tran.flagged_because.should be_nil
      over_two_flagged_suc_tran.dismissed_at.should be_nil
      over_two_flagged_suc_tran.assigned_to.should be_nil
      over_two_flagged_suc_tran.assigned_date.should be_nil
    end
  end

  describe "handling donations where users elected not to enrol in quickdonate" do
    it "should remove trigger_id from one-off donations where a user is not enrolled in quickdonate" do
      donation = create(:donation, user: create(:user), trigger_id: "some trigger id", last_donated_at: 2.months.ago)
      @service.clear_all_out_of_date_one_off_with_triggers(2.weeks.ago)
      donation.reload.trigger_id.should == nil
    end

    it "should not remove trigger_id from one-off donations where a user is enrolled in quickdonate" do
      user_enrolled_in_qd = create(:user, quick_donate_trigger_id: "some trigger id")
      donation = create(:donation, user: user_enrolled_in_qd, trigger_id: "some trigger id", last_donated_at: 2.months.ago)
      @service.clear_all_out_of_date_one_off_with_triggers(2.weeks.ago)
      donation.reload.trigger_id.should == "some trigger id"
    end

    it "should not remove trigger_id from one-off donations younger than a certain date" do
      donation = create(:donation, user: create(:user), trigger_id: "some trigger id", last_donated_at: 6.days.ago)
      @service.clear_all_out_of_date_one_off_with_triggers(1.week.ago)
      donation.reload.trigger_id.should == "some trigger id"
    end

    it "should not remove trigger_id from recurring donations" do
      donation = create(:donation, user: create(:user), trigger_id: "some trigger id", last_donated_at: 2.months.ago, frequency: "weekly")
      @service.clear_all_out_of_date_one_off_with_triggers(2.weeks.ago)
      donation.reload.trigger_id.should == "some trigger id"
    end
  end

  describe "#upgrade_recurring!" do
    let!(:original_amount_in_cents){ 500 }
    let!(:recurring){ create(:recurring_donation, amount_in_cents: original_amount_in_cents) }
    let!(:content_module){ create(:donation_upgrade_module) }
    let!(:upgrade_amount_in_cents){ 100 }

    context "with a vaild upgrade amount" do
      it "should upgrade the donation amount by the upgrade amount" do
        DonationService.upgrade_recurring!(content_module, recurring, upgrade_amount_in_cents)
        recurring.reload
        recurring.amount_in_cents.should == original_amount_in_cents + upgrade_amount_in_cents
      end

      it "should create a donation upgrade record" do
        DonationService.upgrade_recurring!(content_module, recurring, upgrade_amount_in_cents)
        upgrades = DonationUpgrade.where(donation_id: recurring.id, content_module_id: content_module.id)
        expect(upgrades.count).to eq(1)
        upgrade = upgrades.first
        expect(upgrade.original_amount_in_cents).to eq(original_amount_in_cents)
        expect(upgrade.upgrade_amount_in_cents).to eq(upgrade_amount_in_cents)
      end
    end

    context "with an invaild upgrade amount" do
      let!(:upgrade_amount_in_cents){ -100 }

      it "should not upgrade the donation amount" do
        DonationService.upgrade_recurring!(content_module, recurring, upgrade_amount_in_cents)
        expect(DonationUpgrade.count).to be_zero
        recurring.reload
        recurring.amount_in_cents.should == original_amount_in_cents
      end
    end
  end
end
