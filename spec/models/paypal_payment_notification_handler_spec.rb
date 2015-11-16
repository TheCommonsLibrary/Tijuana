require File.expand_path(File.dirname(__FILE__) + "../../spec_helper")

describe PaypalPaymentNotificationHandler do
  include VanityTestHelper

  describe "verify_and_handle_ipn" do

    it "should run asynchronously by creating delayed job" do
      Delayed::Job.count.should == 0
      handler({}, "payload").verify_and_handle_ipn
      Delayed::Job.count.should == 1
    end

    context "without_delay" do

      it "should verify ipn with paypal via SSL" do
        mock_request = double("request", 'open_timeout=' => 'nil', 'read_timeout=' => nil)
        mock_request.should_receive("verify_mode=").with(OpenSSL::SSL::VERIFY_NONE)
        mock_request.should_receive("use_ssl=").with(true)
        Net::HTTP.stub(:new).and_return(mock_request)

        ipn_payload = "This is the payload to verify with paypal"
        mock_request.should_receive(:post).with("/cgi-bin/webscr?cmd=_notify-validate", ipn_payload, 'Content-Length' => "#{ipn_payload.length}").and_return(double("response", body: "SOME RESPONSE"))
        handler({}, ipn_payload).verify_and_handle_ipn_without_delay
      end

      it "should verify ipn and log failure if invalid" do
        setup_ipn_verification_response("INVALID")
        invalid_ipn_payload = "Some Payload"
        Rails.logger.should_receive(:warn).with("PaypalPaymentNotificationHandler IPN verification failed on #{invalid_ipn_payload}")
        handler({}, invalid_ipn_payload).verify_and_handle_ipn_without_delay
      end

      it "should verify ipn and handle ipn if verified" do
        setup_ipn_verification_response("VERIFIED")
        handler = handler({}, "Some Payload")
        handler.should_receive(:handle_ipn)
        handler.verify_and_handle_ipn_without_delay
      end

      # see https://developer.paypal.com/webapps/developer/docs/classic/ipn/integration-guide/IPNIntro/
      it "raises error if receiver_email incorrect" do
        with_page_and_ask
        setup_ipn_verification_response("VERIFIED")
        expect {
          handler( ipn_with('receiver_email' => 'wrong@email.domain') ).verify_and_handle_ipn_without_delay
        }.to raise_error(PaypalPaymentNotificationError)
      end

      it "allows sending to any address on our domain" do
        with_page_and_ask
        setup_ipn_verification_response("VERIFIED")
        expect {
          handler( ipn_with('receiver_email' => 'person@getup.org.au') ).verify_and_handle_ipn_without_delay
        }.not_to raise_error
      end
    end

  end

  describe "handle_ipn" do

    before :each do
      with_page_and_ask
    end

    without_transactional_fixtures do
      let(:originator) { create(:user) }
      let(:action_taker_email) { 'action_taker_payer@email.address.com' }
      let(:email) { create(:email) }
      let(:token) { EmailTrackingToken.encode(originator.id, email.id) }

      let(:deliveries) { ActionMailer::Base.deliveries }
      let(:deliveries_email) { ActionMailer::Base.deliveries.first }
      before(:each) { deliveries.clear }

      it "records the transaction and UAE" do
        with_push_table do

          handler( ipn_with('id' => "#{@page.id}-#{@ask.id}-#{token}-",'payer_email' => action_taker_email, 'txn_type' => 'recurring_payment', 'txn_id' => 'THE_TRANSACTION_REF', 'mc_currency' => 'AUD', 'mc_gross' => "12.34", 'mc_fee' => "1.23", 'payment_status' => 'Completed', 'payment_date' => '20:16:45 Jan 04, 2011 PST')).handle_ipn
          donation = Donation.last
          transaction = Transaction.find_by_donation_id(donation.id)
          transaction.should be_present
          transaction.should be_successful
          transaction.amount_in_cents.should == 1234
          transaction.txn_ref.should == 'THE_TRANSACTION_REF'
          transaction.currency.should == 'AUD'
          transaction.fee_in_cents.should == 123
          transaction.response_code.should == 'Completed'
          transaction.settled_on.should == Date.parse('05 Jan 2011') #(in UTC terms)
          transaction.message.should == "Recurring payment"

          uae = UserActivityEvent.where(user_response_id: transaction.id, user_response_type: transaction.class).first()
          uae.email.should == email
        end
      end

      it "creates a shared connection on the initial transaction" do
        with_push_table do

          handler( ipn_with('id' => "#{@page.id}-#{@ask.id}-#{token}-",'payer_email' => action_taker_email, 'txn_type' => 'recurring_payment', 'txn_id' => 'THE_TRANSACTION_REF', 'mc_currency' => 'AUD', 'mc_gross' => "12.34", 'mc_fee' => "1.23", 'payment_status' => 'Completed', 'payment_date' => '20:16:45 Jan 04, 2011 PST')).handle_ipn
          donation = Donation.last
          transaction = Transaction.find_by_donation_id(donation.id)
          uae = UserActivityEvent.where(user_response_id: transaction.id, user_response_type: transaction.class).first()
          action_taker = User.find_by_email(action_taker_email)
          connection = SharedConnections.find_by_action_taker_id(action_taker)
          connection.should_not be_nil
          connection.originator.should == originator
          connection.user_activity_event.should == uae
        end
      end

      it "should record the email from the token against the donation" do
        with_push_table do

          handler( ipn_with('id' => "#{@page.id}-#{@ask.id}-#{token}-",'payer_email' => action_taker_email, 'txn_type' => 'recurring_payment', 'txn_id' => 'THE_TRANSACTION_REF', 'mc_currency' => 'AUD', 'mc_gross' => "12.34", 'mc_fee' => "1.23", 'payment_status' => 'Completed', 'payment_date' => '20:16:45 Jan 04, 2011 PST')).handle_ipn
          donation = Donation.last
          donation.email.should == email
        end
      end

      context "with a acquisition source tracking token" do
        let!(:acquisition_source){ create(:acquisition_source) }
        let!(:user){ create(:user) }
        let!(:acq_token){ EmailTrackingToken.encode_with_source(acquisition_source.id) }

        it "should record the acquisition source on the UAE" do
          handler( ipn_with('id' => "#{@page.id}-#{@ask.id}-#{acq_token}-",'payer_email' => user.email, 'txn_type' => 'recurring_payment', 'txn_id' => 'THE_TRANSACTION_REF', 'mc_currency' => 'AUD', 'mc_gross' => "12.34", 'mc_fee' => "1.23", 'payment_status' => 'Completed', 'payment_date' => '20:16:45 Jan 04, 2011 PST')).handle_ipn
          uae = user.user_activity_events.actions_taken.last
          expect(uae.acquisition_source).to eq(acquisition_source)
        end
      end

      it 'does not create a shared connection when not the initial transaction' do
        with_push_table do

          donation = create(:donation, paypal_subscr_id: 'A_SUBSCRIPTION_ID', frequency: 'weekly')
          handler( subscription_payment_ipn_with('id' => "#{@page.id}-#{@ask.id}-#{token}-",'payer_email' => action_taker_email, 'subscr_id' => 'A_SUBSCRIPTION_ID', 'txn_id' => 'THE_TRANSACTION_REF', 'mc_currency' => 'AUD', 'mc_gross' => "2.50", 'mc_fee' => "0.23", 'payment_status' => 'Completed', 'payment_date' => '22:08:42 May 13, 2013 PDT')).handle_ipn

          action_taker = User.find_by_email(action_taker_email)
          connection = SharedConnections.find_by_action_taker_id(action_taker)
          connection.should be_nil
        end
      end

      context "when donation is one off" do
        it 'sends receipt email to user' do
          with_push_table do
            handler( ipn_with('id' => "#{@page.id}-#{@ask.id}-#{token}-",'payer_email' => action_taker_email, 'txn_type' => 'one_off', 'txn_id' => 'THE_TRANSACTION_REF', 'mc_currency' => 'AUD', 'mc_gross' => "12.34", 'mc_fee' => "1.23", 'payment_status' => 'Completed', 'payment_date' => '20:16:45 Jan 04, 2011 PST')).handle_ipn
            expect(deliveries_email.subject).to match(/Thanks for your donation Friend/)
            expect(deliveries_email.body).to match(/Thanks for chipping in./)
          end
        end
      end
      context "when transaction is first in recurring doation" do
        it 'sends receipt email to user' do
          with_push_table do
            handler( ipn_with('txn_type' => 'subscr_signup', 'subscr_id' => 'XXX', 'period3' => '/1 W/', 'id' => "#{@page.id}-#{@ask.id}-#{token}-",'payer_email' => action_taker_email, 'txn_id' => 'THE_TRANSACTION_REF', 'mc_currency' => 'AUD', 'mc_amount3' => "12.34", 'mc_fee' => "1.23", 'payment_status' => 'Completed', 'payment_date' => '20:16:45 Jan 04, 2011 PST')).handle_ipn
            handler( ipn_with('txn_type' => 'subscr_payment', 'subscr_id' => 'XXX', 'period3' => '/1 W/', 'id' => "#{@page.id}-#{@ask.id}-#{token}-",'payer_email' => action_taker_email, 'txn_id' => 'THE_TRANSACTION_REF', 'mc_currency' => 'AUD', 'mc_amount3' => "12.34", 'mc_fee' => "1.23", 'payment_status' => 'Completed', 'payment_date' => '20:16:45 Jan 04, 2011 PST')).handle_ipn
            expect(deliveries_email.subject).to match(/Welcome to the GetUp Crew, Friend/)
            expect(deliveries_email.body).to match(/Thanks for joining the GetUp Crew!/)
          end
        end
      end
      context "when transaction happens more than once in recurring doation" do
        let(:donation) { Donation.create!(
            user: originator,
            page: @page,
            content_module: @ask,
            name_on_card: 'blerg jensen',
            payment_method: 'paypal',
            frequency: 'monthly',
            amount_in_cents: 100,
            paypal_subscr_id: 'XXX'
          )
        }
        before(:each) { Transaction.create( donation: donation, successful: true ) }
        it 'only sends receipt email on the the first transaction' do
          with_push_table do
            handler( ipn_with('txn_type' => 'subscr_payment', 'subscr_id' => 'XXX', 'period3' => '/1 W/', 'id' => "#{@page.id}-#{@ask.id}-#{token}-",'payer_email' => action_taker_email, 'txn_id' => 'THE_TRANSACTION_REF', 'mc_currency' => 'AUD', 'mc_amount3' => "12.34", 'mc_fee' => "1.23", 'payment_status' => 'Completed', 'payment_date' => '20:16:45 Jan 04, 2011 PST')).handle_ipn
            expect(deliveries.length).to eql(0)
          end
        end
      end
    end

    context "with a vanity identity encoded in the id" do
      before{ with_page_and_ask }
      let!(:identity){ 'someid' }
      let(:paypal_params){
        {'id' => "#{@page.id}-#{@ask.id}-111-#{identity}-",'payer_email' => 'test@test.com', 'txn_type' => 'recurring_payment', 'txn_id' => 'THE_TRANSACTION_REF', 'mc_currency' => 'AUD', 'mc_gross' => "12.34", 'mc_fee' => "1.23", 'payment_status' => 'Completed', 'payment_date' => '20:16:45 Jan 04, 2011 PST' }
      }

      context "with no matching vanity participant" do

        it "should NOT record a conversion" do
          handler( ipn_with(paypal_params)).handle_ipn
          VanityParticipantConversion.count.should be_zero
        end
      end

      context "with a matching vanity participant" do
        let!(:price_options) { new_ab_test :price_options }
        let!(:participant){ register_participant('price_options', identity, 1) }
        before{ handler( ipn_with(paypal_params).merge({'id' => "#{@page.id}-#{@ask.id}-111-#{identity}-#{experiment_numeric_id(price_options)}"})).handle_ipn }
        it "should record a conversion" do
          VanityParticipantConversion.count.should == 1
        end
      end
    end

    context "with vanity experiments in the ID" do
      let!(:user){ create(:user) }
      let!(:email) {create(:email)}
      let!(:token){ EmailTrackingToken.encode(user.id, email.id) }
      let!(:identity){ 'someid' }
      let!(:experiment_qd) { new_ab_test :qd}
      let!(:experiment_hpd) { new_ab_test :hpd }
      let!(:participant_qd) {register_participant('qd', identity, 1)}
      let!(:participant_hpd) {register_participant('hpd', identity, 1)}

      before do
        with_page_and_ask 
      end

      let(:paypal_params){
        {'id' => "#{@page.id}-#{@ask.id}-111-#{token}",'payer_email' => 'test@test.com', 'txn_type' => 'recurring_payment', 'txn_id' => 'THE_TRANSACTION_REF', 'mc_currency' => 'AUD', 'mc_gross' => "12.34", 'mc_fee' => "1.23", 'payment_status' => 'Completed', 'payment_date' => '20:16:45 Jan 04, 2011 PST' }
      }

      it "should record conversions against the experiments in the ID" do
        handler( ipn_with(paypal_params.merge({'id' => "#{@page.id}-#{@ask.id}-111-#{identity}-#{experiment_numeric_id(experiment_qd)},#{experiment_numeric_id(experiment_hpd)}"}) )).handle_ipn
        VanityParticipantConversion.where(id: participant_qd.id, experiment_id: experiment_qd.id).count.should == 1
        VanityParticipantConversion.where(id: participant_hpd.id, experiment_id: experiment_hpd.id).count.should == 1
      end

      it "should ignore experiments it doesn't recognise" do
        fake_experiment_id = 1298
        expect { handler( ipn_with(paypal_params.merge({'id' => "#{@page.id}-#{@ask.id}-111-#{identity}-#{fake_experiment_id}"}) )).handle_ipn }.not_to raise_error
      end

      it "should be fine with no experiments specified" do
        expect { handler( ipn_with(paypal_params.merge({'id' => "#{@page.id}-#{@ask.id}-111-#{identity}-"}) )).handle_ipn }.not_to raise_error
      end

      it "should be ok with legacy IDs that don't contain experiments" do
        expect { handler( ipn_with(paypal_params.merge({'id' => "#{@page.id}-#{@ask.id}-111-#{identity}"}) )).handle_ipn }.not_to raise_error
      end
    end

    context "with non recurring IPN" do

      it "raises error when donation module does not exist" do
        UserActivityEvent.should_not_receive(:action_taken!)
        expect{ handler(ipn_with('id' => "999-123456--")).handle_ipn }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it "raises error when module is not a donation module" do
        UserActivityEvent.should_not_receive(:action_taken!)
        ask = create(:petition_module)
        ContentModuleLink.create!(:page => @page, :content_module => ask)
        expect{ handler(ipn_with('id' => "#{@page.id}-#{ask.id}--")).handle_ipn }.to raise_error(PaypalPaymentNotificationError)
      end

      it "creates a paypal donation record" do
        UserActivityEvent.should_receive(:action_taken!)
        payer_email = 'payer@email.address.com'
        handler( ipn_with('payer_email' => payer_email, 'mc_gross' => "12.34")).handle_ipn

        donation = Donation.last
        donation.page.should == @page
        donation.content_module.should == @ask
        donation.payment_method.should == 'paypal'
        donation.frequency.should == 'one_off'
        donation.name_on_card.should == payer_email
        donation.amount_in_dollars.should == 12.34
      end

      it "should ignore transactions with no transaction id" do
        UserActivityEvent.should_not_receive(:action_taken!)
        message =  {
          "payment_cycle"          => "Weekly",
          "txn_type"               => "recurring_payment_failed",
          "last_name"              => "Else",
          "next_payment_date"      => "02:00:00 Nov 26, 2014 PST",
          "residence_country"      => "AU",
          "initial_payment_amount" => "0.00",
          "rp_invoice_id"          => "605413",
          "currency_code"          => "AUD",
          "time_created"           => "18:01:58 Mar 22, 2011 PDT",
          "verify_sign"            => "AMucAHwVZ3eTM.cGvbcvbc7Zp24kqjAiNwY9u5NojQL.eRsbjyWhOgVoMv",
          "period_type"            => " Regular",
          "payer_status"           => "verified",
          "tax"                    => "0.00",
          "payer_email"            => "somethingelse@gmail.com",
          "first_name"             => "Someone",
          "receiver_email"         => "donations@getup.org.au",
          "payer_id"               => "QHEKM3UWVSPCG",
          "product_type"           => "1",
          "shipping"               => "0.00",
          "amount_per_cycle"       => "10.00",
          "profile_status"         => "Active",
          "charset"                => "UTF-8",
          "notify_version"         => "3.8",
          "amount"                 => "10.00",
          "outstanding_balance"    => "1710.00",
          "recurring_payment_id"   => "I-M10HEHB1BD23",
          "product_name"           => "Weekly Donation to GetUp",
          "ipn_track_id"           => "28a1f921f543",
          "controller"             => "paypal",
          "action"                 => "ipn",
          "id"                     => "#{@page.id}-#{@ask.id}",
        }
        params = HashWithIndifferentAccess.new.merge!(message)
        old_count = Transaction.count
        handler(params).handle_ipn
        Transaction.count.should == old_count
      end

      it "records a transaction record for the donation" do
        UserActivityEvent.should_receive(:action_taken!)
        handler( ipn_with('txn_type' => 'recurring_payment', 'txn_id' => 'THE_TRANSACTION_REF', 'mc_currency' => 'AUD', 'mc_gross' => "12.34", 'mc_fee' => "1.23", 'payment_status' => 'Completed', 'payment_date' => '20:16:45 Jan 04, 2011 PST')).handle_ipn
        donation = Donation.last
        transaction = Transaction.find_by_donation_id(donation.id)
        transaction.should be_present
        transaction.should be_successful
        transaction.amount_in_cents.should == 1234
        transaction.txn_ref.should == 'THE_TRANSACTION_REF'
        transaction.currency.should == 'AUD'
        transaction.fee_in_cents.should == 123
        transaction.response_code.should == 'Completed'
        transaction.settled_on.should == Date.parse('05 Jan 2011') #(in UTC terms)
        transaction.message.should == "Recurring payment"
      end

      it "records a transaction record for the donation with no fee" do
        UserActivityEvent.should_receive(:action_taken!)
        handler( ipn_with({})).handle_ipn
        donation = Donation.last
        transaction = Transaction.find_by_donation_id(donation.id)
        transaction.should be_present
        transaction.should be_successful
        transaction.fee_in_cents.should == 0
      end

      # see https://developer.paypal.com/webapps/developer/docs/classic/ipn/integration-guide/IPNIntro/
      context "errors on duplicate transaction ids" do

        it "logs but does not raise error with duplicate important features" do
          UserActivityEvent.should_receive(:action_taken!)
          handler(ipn_with({'txn_id' => 'YES'})).handle_ipn

          expect(Rails.logger).to receive(:info).with(/PaypalPaymentNotificationHandler duplicate transaction with same information/)
          handler(ipn_with({'txn_id' => 'YES'})).handle_ipn
        end

        it "raises error with different important features" do
          UserActivityEvent.should_receive(:action_taken!)
          handler(ipn_with({'txn_id' => 'YES', 'mc_gross' => 5.0})).handle_ipn
          expect {
            handler(ipn_with({'txn_id' => 'YES', 'mc_gross' => 10.0})).handle_ipn
          }.to raise_error(PaypalPaymentNotificationError)
        end

      end

      it "records an unsuccessful transaction for an unknown status" do
        UserActivityEvent.should_not_receive(:action_taken!)
        handler( ipn_with('payment_status' => 'Wrong')).handle_ipn
        donation = Donation.last
        transaction = Transaction.find_by_donation_id(donation.id)
        transaction.should be_present
        transaction.should_not be_successful
        transaction.response_code.should == 'Wrong'
      end

      it "creates a user" do
        UserActivityEvent.should_receive(:action_taken!)
        UserMailer.should_receive(:welcome_to_getup).with(an_instance_of(User))
        handler( ipn_with('payer_email' => 'payer@email.address.com', 'first_name' => 'FirstName', 'last_name' => 'LastName', 'address_street' => 'StreetAddress', 'address_city' => 'Suburb', 'address_zip' => '3001')).handle_ipn
        donation = Donation.last
        user = donation.user
        user.email.should == 'payer@email.address.com'
        user.first_name.should == 'FirstName'
        user.last_name.should == 'LastName'
        user.street_address.should == 'StreetAddress'
        user.postcode.should == @postcode_3001
      end

      it "should set the source as paypal" do
        handler( ipn_with('payer_email' => 'payer@email.address.com', 'first_name' => 'FirstName', 'last_name' => 'LastName', 'address_street' => 'StreetAddress', 'address_city' => 'Suburb', 'address_zip' => '3001')).handle_ipn
        user = User.find_by_email('payer@email.address.com')
        uae = UserActivityEvent.find_by_source('paypal')
        uae.activity.should == UserActivityEvent::Activity::SUBSCRIBED
        uae.user_id.should == user.id
      end

      context "with existing user" do

        before :each do
          @existing_user = create(:user, email: 'payer@email.address.com', postcode: @postcode_3001)
        end

        it "updates name fields that are not known in our records" do
          UserActivityEvent.should_receive(:action_taken!)
          UserMailer.should_not_receive(:welcome_to_getup)
          handler( ipn_with('payer_email' => 'payer@email.address.com', 'first_name' => 'FirstName', 'last_name' => 'LastName')).handle_ipn
          donation = Donation.last
          user = donation.user
          user.should == @existing_user
          user.first_name.should == 'FirstName'
          user.last_name.should == 'LastName'
        end

        it "updates address fields that are not known in our records if postcode matches" do
          UserActivityEvent.should_receive(:action_taken!)
          handler( ipn_with('payer_email' => 'payer@email.address.com', 'address_street' => 'StreetAddress', 'address_city' => 'Suburb', 'address_zip' => '3001')).handle_ipn
          donation = Donation.last
          user = donation.user
          user.should == @existing_user
          user.street_address.should == 'StreetAddress'
          user.suburb.should == 'Suburb'
          user.postcode.should == @postcode_3001
        end

        it "updates all address fields if we have no address information (incl no postcode)" do
          UserActivityEvent.should_receive(:action_taken!)
          @existing_user.update_attribute(:postcode_id, nil)
          handler( ipn_with('payer_email' => 'payer@email.address.com', 'address_street' => 'StreetAddress', 'address_city' => 'Suburb', 'address_zip' => '3001')).handle_ipn
          donation = Donation.last
          user = donation.user
          user.should == @existing_user
          user.street_address.should == 'StreetAddress'
          user.suburb.should == 'Suburb'
          user.postcode.should == @postcode_3001
        end

        it "does not update address fields if postcode does not match" do
          UserActivityEvent.should_receive(:action_taken!)
          handler( ipn_with('payer_email' => 'payer@email.address.com', 'first_name' => 'FirstName', 'last_name' => 'LastName', 'address_street' => 'StreetAddress', 'address_city' => 'Suburb', 'address_zip' => '2515')).handle_ipn
          donation = Donation.last
          user = donation.user
          user.should == @existing_user
          user.street_address.should_not == 'StreetAddress'
          user.suburb.should_not == 'Suburb'
          user.postcode.should == @postcode_3001
        end

        it "does not update user fields that are already known in our records" do
          UserActivityEvent.should_receive(:action_taken!)
          @existing_user.update_attributes(first_name: 'OriginalFirst', last_name: 'OriginalLast', street_address: 'OriginalStreet', suburb: "OriginalSuburb", postcode: @postcode_3001)
          handler( ipn_with('payer_email' => 'payer@email.address.com', 'first_name' => 'NewFirstName', 'last_name' => 'NewLastName', 'address_street' => 'NewStreetAddress', 'address_city' => 'NewSuburb', 'address_zip' => '3001')).handle_ipn
          donation = Donation.last
          user = donation.user
          user.should == @existing_user
          user.first_name.should == 'OriginalFirst'
          user.last_name.should == 'OriginalLast'
          user.street_address.should == 'OriginalStreet'
          user.suburb.should == 'OriginalSuburb'
        end
      end


      context "with parent transaction" do

        before :each do
          @original_transaction = create(:transaction, txn_ref: "ORIGINAL_TRANSACTION_REF")
        end

        it "creates new transaction for the existing donation" do
          UserActivityEvent.should_receive(:action_taken!)
          handler( ipn_with('parent_txn_id' => 'ORIGINAL_TRANSACTION_REF', 'txn_id' => 'NEW_TRANSACTION_REF')).handle_ipn
          new_transaction = Transaction.find_by_txn_ref('NEW_TRANSACTION_REF')
          new_transaction.donation_id.should == @original_transaction.donation_id
          new_transaction.refund_of.should_not be_present
        end

        it "link new transaction to original transaction if refunded and mark original transaction as refunded" do
          UserActivityEvent.should_receive(:action_taken!)
          handler( ipn_with('parent_txn_id' => 'ORIGINAL_TRANSACTION_REF', 'txn_id' => 'NEW_TRANSACTION_REF', 'payment_status' => 'Refunded')).handle_ipn
          new_transaction = Transaction.find_by_txn_ref('NEW_TRANSACTION_REF')
          new_transaction.refund_of.should == @original_transaction
          @original_transaction.reload
          @original_transaction.should be_refunded
        end

        it "link new transaction to original transaction if reversed and mark original transaction as refunded" do
          UserActivityEvent.should_receive(:action_taken!)
          handler( ipn_with('parent_txn_id' => 'ORIGINAL_TRANSACTION_REF', 'txn_id' => 'NEW_TRANSACTION_REF', 'payment_status' => 'Reversed')).handle_ipn
          new_transaction = Transaction.find_by_txn_ref('NEW_TRANSACTION_REF')
          new_transaction.refund_of.should == @original_transaction
          @original_transaction.reload
          @original_transaction.should be_refunded
        end

        it "creates new transaction even if original transaction does not exist as we have run without paypal processing for so long" do
          UserActivityEvent.should_receive(:action_taken!)
          handler( ipn_with('parent_txn_id' => 'DOES_NOT_EXISTS', 'txn_id' => 'NEW_TRANSACTION_REF', 'payment_status' => 'Refunded')).handle_ipn
          new_transaction = Transaction.find_by_txn_ref('NEW_TRANSACTION_REF')
          new_transaction.should be_present
          new_transaction.donation.should be_present
        end

        it "marks a reversal as unsuccessful if reversal cancellation message is received" do
          UserActivityEvent.should_receive(:action_taken!)
          handler( ipn_with('parent_txn_id' => 'ORIGINAL_TRANSACTION_REF', 'txn_id' => 'REVERSAL_TRANSACTION_REF', 'payment_status' => 'Reversed', 'reason_code' => 'unauthorized_claim')).handle_ipn
          reversal_transaction = Transaction.find_by_txn_ref('REVERSAL_TRANSACTION_REF')
          reversal_transaction.should be_present
          reversal_transaction.should be_successful
          reversal_transaction.response_code.should == 'Reversed'
          reversal_transaction.status_reason.should == 'unauthorized_claim'

          handler( ipn_with('parent_txn_id' => 'ORIGINAL_TRANSACTION_REF', 'txn_id' => 'REVERSAL_TRANSACTION_REF', 'payment_status' => 'Canceled_Reversal', 'reason_code' => 'totally_unauthorized_claim')).handle_ipn

          reversal_transaction.reload
          reversal_transaction.should_not be_successful
          reversal_transaction.response_code.should == 'Canceled_Reversal'
        end
      end
    end

    context "subscription" do

      context "setup message" do

        it "should create donation with user" do
          UserActivityEvent.should_not_receive(:action_taken!)
          handler( subscription_setup_ipn_with('mc_amount3' => '5.0', 'subscr_id' => 'THE_SUBSCRIPTION_ID', 'payer_email' => 'payer@email.address.com', 'first_name' => 'FirstName', 'last_name' => 'LastName')).handle_ipn
          donation = Donation.last
          donation.paypal_subscr_id.should == 'THE_SUBSCRIPTION_ID'
          donation.amount_in_cents.should == 500
          donation.should be_active
          donation.user.email.should == 'payer@email.address.com'
          donation.user.first_name.should == 'FirstName'
          donation.user.last_name.should == 'LastName'
        end

        it "should create weekly donation" do
          UserActivityEvent.should_not_receive(:action_taken!)
          handler( subscription_setup_ipn_with('period3' => '1 W')).handle_ipn
          donation = Donation.last
          donation.frequency.should == 'weekly'
        end

        it "should create monthly donation" do
          UserActivityEvent.should_not_receive(:action_taken!)
          handler( subscription_setup_ipn_with('period3' => '1 M')).handle_ipn
          donation = Donation.last
          donation.frequency.should == 'monthly'
        end

        it "should create yearly donation" do
          UserActivityEvent.should_not_receive(:action_taken!)
          handler( subscription_setup_ipn_with('period3' => '1 Y')).handle_ipn
          donation = Donation.last
          donation.frequency.should == 'annual'
        end

        it "should raise error for unknown donation frequency" do
          UserActivityEvent.should_not_receive(:action_taken!)
          handler = handler( subscription_setup_ipn_with('period3' => '5 S'))
          expect {
            handler.handle_ipn
          }.to raise_error(PaypalPaymentNotificationError)
        end

        it "should update amount and frequency of existing donation record, as a payment message may be been processed first and created a dummy donation" do
          UserActivityEvent.should_not_receive(:action_taken!)
          donation = create(:donation, paypal_subscr_id: 'THE_SUBSCRIPTION_ID', frequency: 'one_off')
          handler( subscription_setup_ipn_with('subscr_id' => 'THE_SUBSCRIPTION_ID', 'mc_amount3' => '5.0', 'period3' => '1 W')).handle_ipn
          donation.reload
          donation.frequency.should == 'weekly'
          donation.amount_in_cents.should == 500
          donation.should be_active
        end

      end

      context "payment message" do

        it "should create transaction belonging to subscription donation" do
          UserActivityEvent.should_receive(:action_taken!)
          donation = create(:donation, paypal_subscr_id: 'A_SUBSCRIPTION_ID', frequency: 'weekly')
          handler( subscription_payment_ipn_with('subscr_id' => 'A_SUBSCRIPTION_ID', 'txn_id' => 'THE_TRANSACTION_REF', 'mc_currency' => 'AUD', 'mc_gross' => "2.50", 'mc_fee' => "0.23", 'payment_status' => 'Completed', 'payment_date' => '22:08:42 May 13, 2013 PDT')).handle_ipn
          transaction = donation.transactions.first
          transaction.should be_present
          transaction.should be_successful
          transaction.amount_in_cents.should == 250
          transaction.txn_ref.should == 'THE_TRANSACTION_REF'
          transaction.currency.should == 'AUD'
          transaction.fee_in_cents.should == 23
          transaction.response_code.should == 'Completed'
          transaction.settled_on.should == Date.parse('14 May 2013') #(in UTC terms)
        end

        it "should create a donation if there is no parent donation" do
          UserActivityEvent.should_receive(:action_taken!)
          handler( subscription_payment_ipn_with('subscr_id' => 'THE_SUBSCRIPTION_ID') ).handle_ipn
          donation = Donation.last
          donation.frequency.should == 'one_off'
          donation.paypal_subscr_id.should == 'THE_SUBSCRIPTION_ID'
        end

      end

      context "with failure message" do
        it "should mark transaction as failed existing donation and use amount from donation" do
          UserActivityEvent.should_not_receive(:action_taken!)
          donation = create(:donation, paypal_subscr_id: 'THE_SUBSCRIPTION_ID', :amount_in_cents => 5366)
          handler(subscription_ipn_with(
               'subscr_id' => 'THE_SUBSCRIPTION_ID',
               'txn_type' => 'subscr_failed'
          )).handle_ipn
          transaction = donation.transactions.last
          transaction.should_not be_successful
          transaction.fee_in_cents.should == 0
          transaction.amount_in_cents.should == 5366
        end
      end

      context "with cancel message" do
        it "should deactivate existing donation" do
          UserActivityEvent.should_not_receive(:action_taken!)
          donation = create(:donation, paypal_subscr_id: 'THE_SUBSCRIPTION_ID')
          handler( subscription_ipn_with('subscr_id' => 'THE_SUBSCRIPTION_ID', 'txn_type' => 'subscr_cancel')).handle_ipn
          donation.reload
          donation.should_not be_active
        end
      end

      context "with end of term message" do
        it "should deactivate existing donation" do
          UserActivityEvent.should_not_receive(:action_taken!)
          # It is not worth trying to handle this by flagging etc, as we never set a limited term - so this means the donor has limited the term (if that is even possible)
          donation = create(:donation, paypal_subscr_id: 'THE_SUBSCRIPTION_ID')
          handler( subscription_ipn_with('subscr_id' => 'THE_SUBSCRIPTION_ID', 'txn_type' => 'subscr_eot')).handle_ipn
          donation.reload
          donation.should_not be_active
        end
      end

      context "with subscription modification message" do
        it "should ignore" do
          UserActivityEvent.should_not_receive(:action_taken!)
          # We do not offer any way to modify the subscription, so we are not really interested, but it should not blow up.
          donation = create(:donation, paypal_subscr_id: 'THE_SUBSCRIPTION_ID')
          handler( subscription_ipn_with('subscr_id' => 'THE_SUBSCRIPTION_ID', 'txn_type' => 'subscr_modify')).handle_ipn
          donation.reload
          donation.should be_active
        end
      end
      
      it "should ignore new dispute filed message" do
        UserActivityEvent.should_not_receive(:action_taken!)
        expect(Rails.logger).to receive(:info).with(/PaypalPaymentNotificationHandler ignoring/)

        donation = create(:donation, paypal_subscr_id: 'THE_SUBSCRIPTION_ID')
        handler(subscription_ipn_with('subscr_id' => 'THE_SUBSCRIPTION_ID', 'txn_type' => 'new_case')).handle_ipn
      end
    end

    context "recurring payment (distinct from subscription)" do
      let(:recurring_payment) { subscription_payment_ipn_with('txn_type' => 'recurring_payment').except('subscr_id') }

      context "with a donation" do
        let!(:donation) { create(:donation, paypal_subscr_id: 'A_RECURRING_ID', frequency: 'weekly') }
        let(:transaction) { donation.transactions.first }
        let(:payload) {{ 'recurring_payment_id' => 'A_RECURRING_ID', 'mc_gross' => '2.5' }}

        it "creates a transaction belonging to the recurring payment donation" do
          handler(recurring_payment.merge(payload)).handle_ipn
          expect(transaction).to be_successful
          expect(transaction.amount_in_cents).to eq(250)
        end
      end

      context "without a donation" do
        let(:donation) { Donation.last }
        let(:payload) {{ 'recurring_payment_id' => 'THE_RECURRING_ID', 'payment_cycle' => 'Yearly' }}

        it "creates a donation with the correct frequency" do
          handler(recurring_payment.merge(payload)).handle_ipn
          expect(donation.frequency).to eq('annual')
          expect(donation.paypal_subscr_id).to eq('THE_RECURRING_ID')
        end
      end
    end

    context "when case_type is chargeback" do
      it "gets logged only (no error message)" do
        expect(Rails.logger).to receive(:info).with(/PaypalPaymentNotificationHandler ignoring chargeback/)
        ipn = ipn_with("case_type" => "chargeback").except("mc_gross")
        handler(ipn).handle_ipn
      end
    end
  end


  describe "utility functions" do

    it "should convert currency to integral cents values" do
      PaypalPaymentNotificationHandler.send(:currency_to_cents, "100.99").should eql(10099)
      PaypalPaymentNotificationHandler.send(:currency_to_cents, "0").should eql(0)
      PaypalPaymentNotificationHandler.send(:currency_to_cents, "0.00").should eql(0)
      PaypalPaymentNotificationHandler.send(:currency_to_cents, "-50.00").should eql(-5000)
      PaypalPaymentNotificationHandler.send(:currency_to_cents, "-48.50").should eql(-4850)
    end

  end

  def with_page_and_ask
    @postcode_3001 = Postcode.create!(:number => "3001", :latitude => -37.811931, :longitude => 144.962711)
    @page = create(:page_with_parent)
    @ask = create(:donation_module)
    ContentModuleLink.create!(:page => @page, :content_module => @ask)
  end

  #See https://developer.paypal.com/webapps/developer/docs/classic/ipn/integration-guide/IPNandPDTVariables/
  def ipn_with(overrides)
    {
        'id' => "#{@page.id}-#{@ask.id}",
        'mc_gross' => '1.00',
        'payment_status' => 'Completed',
        'payer_email' => 'payer@email.address.com',
        'receiver_email' => "donate_1294198178_biz@getup.org.au",
        'payment_date' => '00:00:00 Jan 01, 2000 PST',
        'receiver_id' => AppConstants.paypal_business_id,
        'txn_type' => 'web_accept',
        'txn_id' => SecureRandom.base64(12),
    }.merge(overrides)
  end

  def subscription_setup_ipn_with(overrides)
    {
        'id' => "#{@page.id}-#{@ask.id}",
        'first_name' => 'FirstName',
        'last_name' => 'LastName',
        'payer_email' => 'test@test.com',
        'mc_amount3' => '5.0',
        'mc_currency' => 'AUD',
        'period3' => '1 W',
        'residence_country' => 'AU',
        'subscr_date' => '22:08:41 May 13, 2013 PDT',
        'subscr_id' => 'I-JABPPJJ00DMR',
        'txn_type' => 'subscr_signup',
    }.merge(overrides)
  end

  def subscription_payment_ipn_with(overrides)
    {
        'id' => "#{@page.id}-#{@ask.id}",
        'first_name' => 'FirstName',
        'last_name' => 'LastName',
        'payer_email' => 'test@test.com',
        'mc_currency' => 'AUD',
        'mc_fee' => '0.42',
        'mc_gross' => '5.0',
        'payment_date' => '22:08:42 May 13, 2013 PDT',
        'payment_status' => 'Completed',
        'receiver_id' => AppConstants.paypal_business_id,
        'subscr_id' => 'I-JABPPJJ00DMR',
        'txn_type' => 'subscr_payment',
        'txn_id' => SecureRandom.base64(12),
    }.merge(overrides)
  end

  def subscription_ipn_with(overrides)
    {
        'payer_email' => 'test@test.com',
        'subscr_id' => 'I-JABPPJJ00DMR',
        'txn_id' => SecureRandom.base64(12),
    }.merge(overrides)
  end

  def setup_ipn_verification_response(paypal_response)
    Net::HTTP.stub(:new).and_return(double("request", 'open_timeout=' => 'nil', 'read_timeout=' => nil, 'verify_mode=' => nil, 'use_ssl=' => nil, 'post' => double("response", body: paypal_response)))
  end

  def handler(params, raw_post = "")
    PaypalPaymentNotificationHandler.new(params, raw_post)
  end

end
