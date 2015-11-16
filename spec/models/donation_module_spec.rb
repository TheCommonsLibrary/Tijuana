require File.dirname(__FILE__) + '/../spec_helper.rb'

describe DonationModule do

  include VanityTestHelper
  include QuickdonateHelper

  def build_donation_module(attrs)
    m = build(:donation_module)
    m.attributes = attrs
    m.cookies = cookies
    m
  end

  before do
    setup_fake_context
    Vanity.context.stub(:vanity_identity).and_return(1)
    @mobile_amounts_exp = Vanity.playground.experiment(:amounts_shown_on_mobile)
    @mobile_amounts_exp.chooses(:subset)
  end

  describe '#post_action_data_for_logger' do
    it "should return hash of donation amount in dollars" do
      user = create(:user, email: 'noone@example.com')
      ask = create(:donation_module)
      ask.session = session
      ask.flash = flash
      ask.cookies = cookies
      page = create(:page_with_parent)
      email = create(:email)
      donation_params = {:donation => attributes_for(:donation, :card_number => PaymentGateways::CARD_SUCCESS)}
      ask.update_action_attributes_and_validate(donation_params)
      ask.take_action(user, page, email, donation_params).should == true
      ask.post_action_data_for_logger[:donated_amount_in_dollars].should == 30.0
    end
  end

  describe '#pre_action_data_for_logger' do
    context 'a user with donation history and personalised amounts disabled' do
      it 'should show hash of user with personalised amounts disabled' do
        user = create(:user)
        donation = create(:donation, user: user)
        create(:transaction, donation: donation, amount_in_cents: 5000)
        dm = build_donation_module(use_fixed_amounts: true)
        dm.donations << donation
        result = dm.pre_action_data_for_logger({user: user})
        result.should == {:hpda=>nil, :amounts_list=>"100, 50*, 30*, 12*, 5, 3".split(','), use_fixed_amounts: true, :user_known=>true}
      end
    end

    context 'a user with no donation history and personalised amounts enabled' do
      let!(:experiment){ Vanity.playground.experiments[:personalised_amounts_from_cookie_v2] }

      it 'should show hash of user who was not offered personalised amounts' do
        user = create(:user)
        dm = build_donation_module(use_fixed_amounts: false)
        result = dm.pre_action_data_for_logger({user: user})
        result.should == {:hpda=>nil, :amounts_list=>"100, 50*, 30*, 12*, 5, 3".split(','), use_fixed_amounts: false, :user_known=>true}
      end
    end
  end

  describe "#default_amount_in_dollars" do
    before(:each) do
      @dm = build_donation_module(suggested_amounts: '12,15,20',
                                      personalised_amounts: '100%*, 200%',
                                      personalised_default_amount: '200%',
                                      default_amount: '15',
                                      eligible_for_personalised_donation_tests: false)
    end

    it "returns non-personalised default amount if no user" do
      @dm.default_amount_in_dollars(nil).should == '15'
    end

    it 'returns non-personalised default amount if no HPDA' do
      @dm.default_amount_in_dollars(create(:user)).should == '15'
    end

    it 'returns personalised donation amounts if user with HPDA' do
      user = create(:user)
      donation = create(:donation, user: user)
      transaction = create(:transaction, donation: donation, amount_in_cents: 5000)
      @dm.default_amount_in_dollars(user).should == '100'
    end

    it 'returns cap if cap and user exist and HDPA > cap' do
      @dm.personalised_cap = 30
      user = create(:user)
      donation = create(:donation, user: user)
      transaction = create(:transaction, donation: donation, amount_in_cents: 5000)
      @dm.default_amount_in_dollars(user).should == '60'
    end

    it 'uses floor for small donors' do
      user = create(:user)
      donation = create(:donation, user: user)
      transaction = create(:transaction, donation: donation, amount_in_cents: 500)
      @dm.default_amount_in_dollars(user).should == (DonationModule::HPDA_FLOOR * 2).to_s
    end

  end

  describe "#amounts_list" do
    before(:each) do
      @dm = build_donation_module(suggested_amounts: "12,15,20",
                                      personalised_amounts: "100%*, 200%",
                                      eligible_for_personalised_donation_tests: false,
                                      personalised_cap: '100')
    end

    it "returns non-personalised amounts if no user" do
      @dm.amounts_list(nil).should == ["12", "15", "20"]
    end

    it "returns non-personalised amounts if no HPDA" do
      @dm.amounts_list(create(:user)).should == ["12", "15", "20"]
    end

    it "returns personalised donation amounts if user with HPDA" do
      user = create(:user)
      donation = create(:donation, user: user)
      transaction = create(:transaction, donation: donation, amount_in_cents: 5000)
      @dm.amounts_list(user).should == ["50*", "100"]
    end

    it "use floor instead of HPDA if low donor" do
      user = create(:user)
      donation = create(:donation, user: user)
      transaction = create(:transaction, donation: donation, amount_in_cents: 500)
      @dm.amounts_list(user).should == ["10*", "20"]
    end

  end



  describe "#personalised_amounts_list" do
    let!(:user){ create(:user) }
    it "calculate percentages, drop extra whitespace and keep stars" do
      dm = build_donation_module(personalised_amounts: " 5*, 75%,100%*,125%*,  5000",
                                      eligible_for_personalised_donation_tests: false,
                                      personalised_cap: '300')
      dm.personalised_amounts_list(user, 200).should == ['5*', '150', '200*', '250*', '5000']
    end

    it "use cap instead of HPDA if set" do
      dm = build_donation_module(personalised_amounts: "5*, 100%*, 125%",
                                      eligible_for_personalised_donation_tests: false,
                                      personalised_cap: '100')
      dm.personalised_amounts_list(user, 200).should == ['5*', '100*', '125']
    end

    it "support no cap" do
      dm = build_donation_module(personalised_amounts: "5*, 100%*, 125%", eligible_for_personalised_donation_tests: false)
      dm.personalised_amounts_list(user, 200).should == ['5*', '200*', '250']
    end

    it "de-duplicates donation amounts and keeps *" do
      dm = build_donation_module(personalised_amounts: "20, 25*, 100%*, 125%, 500", eligible_for_personalised_donation_tests: false)
      dm.personalised_amounts_list(user, 20).should == ['20*', '25*', '500']
    end
  end

  describe "custom fields" do
    it "can be stored" do
      dm = build(:donation_module)
      dm.custom_fields = [{name: 'first'}, {name: 'second'}]
      dm.save!
      retrieved_dm = DonationModule.find(dm.id)
      retrieved_dm.custom_fields.should == [{name: 'first'}, {name: 'second'}]
    end

    it "should handle empty yaml gracefully" do
      dm = build(:donation_module)
      dm.custom_fields_as_yaml = ''
      dm.valid?.should be true
    end
  end

  it "should create some sensible defaults" do
    dm = DonationModule.create
    dm.button_text.should == 'Donate!'
    amounts = dm.suggested_amounts.split(', ')
    amounts.length.should > 3
    amounts.should include("12*")
    dm.default_amount.should == '12'
    dm.donation.recurring?.should be false
    dm.personalised_amounts.should include("70")
    dm.personalised_default_amount.should == "70"
    dm.personalised_cap.should == "300"
  end

  describe "validations" do
    it "should require a title between 3 and 128 characters" do
      build_donation_module(:title => "Save the kittens!").should be_valid
      build_donation_module(:title => "X" * 128).should be_valid
      build_donation_module(:title => "X" * 129).should have(1).errors_on :title
      build_donation_module(:title => "AB").should have(1).errors_on :title
    end

    it "should require a thermometer threshold greater than or equal to 0" do
      build_donation_module(:thermometer_threshold => 1).should be_valid
      build_donation_module(:thermometer_threshold => 0).should be_valid
      build_donation_module(:thermometer_threshold => nil).should have(1).errors_on :thermometer_threshold
    end

    it "requires each suggested amount to be an integer greater than 1" do
      build_donation_module(:default_amount => "30", :suggested_amounts => "12, 20, 30").should be_valid
      build_donation_module(:default_amount => "30", :suggested_amounts => "0, 30").should have(1).errors_on :suggested_amounts
      build_donation_module(:default_amount => "30", :suggested_amounts => "12, 20, 30, ABCDEF").should have(1).errors_on :suggested_amounts
    end

    it "requires default amount to be one of the suggested amounts" do
      build_donation_module(:default_amount => "12", :suggested_amounts => "12, 20, 30").should be_valid
      build_donation_module(:default_amount => "50", :suggested_amounts => "12, 20, 30").should have(1).errors_on :default_amount
    end

    it 'requires personalised amounts to be either a percentage or an integer greater than 1' do
      build_donation_module(:personalised_default_amount => "10", :personalised_amounts => "10, 20%, 30%*, 40*", eligible_for_personalised_donation_tests: false).should be_valid
      build_donation_module(:personalised_default_amount => "10", :personalised_amounts => "10, 10.5, 100.50, 150.5%", eligible_for_personalised_donation_tests: false).should be_valid
      build_donation_module(:personalised_default_amount => "10", :personalised_amounts => "10, 20%, 30%*a, 40*", eligible_for_personalised_donation_tests: false).should have(1).errors_on :personalised_amounts
      build_donation_module(:personalised_default_amount => "10", :personalised_amounts => "10, a20%, 30%*, 40*", eligible_for_personalised_donation_tests: false).should have(1).errors_on :personalised_amounts
      build_donation_module(:personalised_default_amount => "10", :personalised_amounts => "10, a", eligible_for_personalised_donation_tests: false).should have(1).errors_on :personalised_amounts
      build_donation_module(:personalised_default_amount => "10", :personalised_amounts => "10, -1", eligible_for_personalised_donation_tests: false).should have(1).errors_on :personalised_amounts
    end

    it "requires personalised default amount to be one of the personalised amounts" do
      build_donation_module(:personalised_default_amount => "10", :personalised_amounts => "10, 20, 30", eligible_for_personalised_donation_tests: false).should be_valid
      build_donation_module(:personalised_default_amount => "10", :personalised_amounts => "10", eligible_for_personalised_donation_tests: false).should be_valid
      build_donation_module(:personalised_default_amount => "10%", :personalised_amounts => "10%, 20, 30", eligible_for_personalised_donation_tests: false).should be_valid
      build_donation_module(:personalised_default_amount => "10%", :personalised_amounts => "10%*, 20, 30", eligible_for_personalised_donation_tests: false).should be_valid
      build_donation_module(:personalised_default_amount => "10", :personalised_amounts => "10*, 20, 30", eligible_for_personalised_donation_tests: false).should be_valid
      build_donation_module(:personalised_default_amount => "10", :personalised_amounts => " 10 , 20, 30", eligible_for_personalised_donation_tests: false).should be_valid
      build_donation_module(:personalised_default_amount => "10", :personalised_amounts => "10%, 20, 30", eligible_for_personalised_donation_tests: false).should have(1).errors_on :personalised_default_amount
      build_donation_module(:personalised_default_amount => "10", :personalised_amounts => "10%, 20, 30, 100%, 1010", eligible_for_personalised_donation_tests: false).should have(1).errors_on :personalised_default_amount
      build_donation_module(:personalised_default_amount => "10", :personalised_amounts => "10 1, 20, 30", eligible_for_personalised_donation_tests: false).should have(1).errors_on :personalised_default_amount
    end

    it "requires a single default frequency" do
      build_donation_module(:frequency_options => {'one_off' => 'default', 'weekly' => 'hidden'}).should be_valid
      build_donation_module(:frequency_options => {'monthly' => 'default', 'weekly' => 'default'}).should have(1).errors_on :frequency_options
      build_donation_module(:frequency_options => {'one_off' => 'hidden', 'weekly' => 'optional'}).should have(1).errors_on :frequency_options
    end

    it "is invalid to enable paypal if commence_donation_at is set" do
      build_donation_module(disable_paypal: '0', commence_donation_at: '01-01-2000').should have(1).errors_on :commence_donation_at
    end
    it "is valid to have commence_donation_at if paypal is disabled" do
      build_donation_module(disable_paypal: '1', commence_donation_at: '01-01-2000').should be_valid
    end

    it "is not valid to have paypal enabled when using custom form fields" do
      dm = build_donation_module(disable_paypal: '0', custom_fields: {form_fields: [name: 'some field']})
      dm.should have(1).errors_on :custom_fields
      dm.errors.full_messages.first.should == 'Custom fields are not supported by PayPal.'
    end

    it "is valid to have custom form fields when paypal is disabled" do
      dm = build_donation_module(disable_paypal: '1', custom_fields: {form_fields: [name: 'some field']})
      dm.should be_valid
    end

    it "requires quick donate text if quick donate is enabled" do
      dm = build_donation_module(quick_donate_enabled: '1', quick_donate_text: "")
      dm.should have(1).errors_on :quick_donate_text
    end

    it "is valid if quick donate is not enabled and no quick donate text" do
      dm = build_donation_module(quick_donate_enabled: '0', quick_donate_text: "")
      dm.should be_valid
    end
    
    it "should allow personalized amounts for one off asks" do
      build_donation_module(
        :personalised_default_amount => "10%", 
        :personalised_amounts => "10%, 20, 30",
        :frequency_options => { 'one_off' => 'default', 'weekly' => 'hidden', 'monthly' => 'hidden', 'annual' => 'hidden' }
      ).should be_valid
    end

    it "should not allow personalized amounts for recurring asks" do
      build_donation_module(
        :personalised_default_amount => "",
        :personalised_amounts => "",
        :frequency_options => { 'one_off' => 'hidden', 'weekly' => 'default', 'monthly' => 'optional', 'annual' => 'optional' },
        eligible_for_personalised_donation_tests: false
      ).should be_valid

      build_donation_module(
        :personalised_default_amount => "10%", 
        :personalised_amounts => "10%, 20, 30",
        use_fixed_amounts: false,
        :frequency_options => { 'one_off' => 'hidden', 'weekly' => 'default', 'monthly' => 'optional', 'annual' => 'optional' }
      ).should_not be_valid
    end

    context "badly formed yaml" do
      before :each do
        @invalid_yaml = "test:\n  valid:\n invalid: X"
        @dm = build_donation_module(disable_paypal: '0', custom_fields: {original: 'original value'})
        @dm.custom_fields_as_yaml = @invalid_yaml
      end

      it "is not valid" do
        @dm.should have(1).errors_on :custom_fields
      end

      it "blats custom_fields" do
        @dm.custom_fields_as_yaml.should == @invalid_yaml
        @dm.custom_fields.should be_nil
      end
    end

    it "is valid to have well formed yaml" do
      dm = build_donation_module(disable_paypal: '0', custom_fields_as_yaml: "test:\n  valid: X")
      dm.should be_valid
    end

    context "not credit card payment" do
      let(:donation_params) { {:donation => attributes_for(:donation, :card_number => PaymentGateways::CARD_SUCCESS).merge({payment_method: 'paypal'})} }
      let!(:donation_module) { create(:donation_module) }
      let(:user) { create(:user) }
      let(:page) { create(:page_with_parent) }
      let(:email) { create(:email) }

      before do
        donation_module.session = session
        donation_module.flash = flash
        donation_module.cookies = cookies
      end

      it "should fail and notify user" do
        donation_module.should_receive(:notify_user).at_least(:once)
        donation_module.update_action_attributes_and_validate(donation_params)
        donation_module.take_action(user, page, email, donation_params).should == false
      end
    end
  end

  describe 'paypal_disabled?' do
    it "should not be disabled for nil" do
      create(:donation_module, disable_paypal: nil).should_not be_paypal_disabled
    end
    it "should not be disabled for 0" do
      create(:donation_module, disable_paypal: '0').should_not be_paypal_disabled
    end
    it "should be disabled for 1" do
      create(:donation_module, disable_paypal: '1').should be_paypal_disabled
    end
  end

  describe "frequency options" do
    it "knows if it only allows one-off payments" do
      dm = create(:donation_module, :frequency_options => {'one_off' => 'default', 'weekly' => 'hidden'})
      dm.only_allow_one_off_payment?.should == true
      dm.frequency_options['weekly'] = 'optional'
      dm.only_allow_one_off_payment?.should == false
    end

    it "constructs a list of available frequencies suitable for use as dropdown options" do
      dm = create(:donation_module, :frequency_options => {'one_off' => 'default', 'weekly' => 'hidden', 'monthly' => 'optional'}, eligible_for_personalised_donation_tests: false)
      dm.available_frequencies_for_select.should == [['Donate Once', 'one_off'], ['Donate Monthly', 'monthly']]
    end
  end

  describe "building a donation" do
    it "should default the amount and frequency from the content module" do
      dm = DonationModule.new(:default_amount => "33", :frequency_options => {'one_off' => 'optional', 'weekly' => 'default'}, eligible_for_personalised_donation_tests: false)
      donation = dm.donation
      donation.amount_in_cents.should == 3300
      donation.frequency.should == 'weekly'
    end
  end


  def session
    @session ||= HashWithIndifferentAccess.new
  end
  
  def flash
    @flash ||= ActionDispatch::Flash::FlashHash.new
  end

  def cookies
    unless @cookies
      @cookies = double()
      @cookies.stub(:signed).and_return({})
    end
    @cookies
  end

  def set_quick_donate_user_id(id)
    cookies.signed[:quick_donate_user_id] = id
  end

  describe "taking an action" do
    before(:each) do
      @user = create(:user, email: 'noone@example.com')
      @ask = create(:donation_module)
      @ask.session = session
      @ask.flash = flash
      @ask.cookies = cookies
      @page = create(:page_with_parent)
      @email = create(:email)
    end

    it "should process the donation" do
      donation_params = {:donation => attributes_for(:donation, :card_number => PaymentGateways::CARD_SUCCESS)}
      @ask.update_action_attributes_and_validate(donation_params)
      @ask.take_action(@user, @page, @email, donation_params).should == true
      @ask.donation.user.should == @user
      @ask.donation.email.should == @email
      @ask.donation.transactions.first.should be_successful
      @ask.analytics_events_js.should include "ga('send', 'event', 'donation module', 'donated', 'one_off', 30.0);"
    end
    
    it "should allow multiple donations from a single user" do
      donation_params = {:donation => attributes_for(:donation, :card_number => PaymentGateways::CARD_SUCCESS)}
      2.times do
        @ask.update_action_attributes_and_validate(donation_params)
        @ask.take_action(@user, @page, nil, donation_params)
      end
    end
    
    it "should reprocess the existing donation if payment fails rather than creating mutiple records" do
      params = {:donation => attributes_for(:donation, :card_number => PaymentGateways::CARD_FAILURE)}
      first_donation = @ask.donation
      @ask.update_action_attributes_and_validate(params)
      @ask.take_action(@user, @page, nil, params).should == false

      first_donation.should be_persisted
      first_donation.transactions.last.should_not be_successful

      params = {:donation => attributes_for(:donation, :card_number => PaymentGateways::CARD_SUCCESS).merge(:id => first_donation.id)}
      @ask = DonationModule.find(@ask.id) # Can't use @ask.reload as we need to lose memoized donation
      @ask.update_action_attributes_and_validate(params)
      @ask.cookies = cookies
      @ask.take_action(@user, @page, nil, params).should == true

      first_donation.transactions.count.should == 2
      first_donation.transactions.last.should be_successful
    end

    it "should NOT reprocess the existing donation, but create a new donation if original donation does not allow modification (eg. if it was successful)" do
      # given
      params = {:donation => attributes_for(:donation, :card_number => PaymentGateways::CARD_SUCCESS)}
      first_donation = @ask.donation
      @ask.update_action_attributes_and_validate(params)
      @ask.take_action(@user, @page, nil, params)

      first_donation.should be_persisted
      first_donation.transactions.last.should be_successful

      # when
      params = {:donation => attributes_for(:donation, :card_number => PaymentGateways::CARD_SUCCESS).merge(:id => first_donation.id)}
      @ask = DonationModule.find(@ask.id) # Can't use @ask.reload as we need to lose memoized donation
      @ask.update_action_attributes_and_validate(params)
      @ask.cookies = cookies
      @ask.take_action(@user, @page, nil, params).should == true

      #then
      @ask.donation.should_not == first_donation
      first_donation.transactions.count.should == 1
    end

    specify { it_should_flash_error_message_upon_active_merchant_error(ActiveMerchant::ResponseError.new(502)) }
    specify { it_should_flash_error_message_upon_active_merchant_error(ActiveMerchant::ConnectionError.new(504, 'The connection to the remote server timed out')) }

    def it_should_flash_error_message_upon_active_merchant_error(error)
      params = {:donation => attributes_for(:donation, :card_number => PaymentGateways::CARD_SUCCESS)}
      @service = double()
      DonationService.stub(:new).and_return(@service)
      @service.stub(:process!) { raise error }

      @ask.should_receive(:notify_user)
      @ask.should_receive(:notify_email)

      @ask.update_action_attributes_and_validate(params)
      @ask.take_action(@user, @page, nil, params).should be false
    end

    it "should update users quickdonate trigger id if user is enrolled but a non-quick donation is made" do
      user = create(:user, quick_donate_trigger_id: 'ORIGINAL')
      params = {:donation => attributes_for(:donation, :card_number => PaymentGateways::CARD_SUCCESS)}
      @ask.update_action_attributes_and_validate(params)
      @ask.take_action(user, @page, nil, params)
      user.reload
      user.quick_donate_trigger_id.should == @ask.donation.trigger_id
    end

    it "should NOT update users quickdonate trigger id if user is NOT enrolled" do
      user = create(:user, quick_donate_trigger_id: '')
      params = {:donation => attributes_for(:donation, :card_number => PaymentGateways::CARD_SUCCESS)}
      @ask.update_action_attributes_and_validate(params)
      @ask.take_action(user, @page, nil, params)
      user.reload
      user.quick_donate_trigger_id.should be_blank
    end

    it "should NOT update users quickdonate trigger id if transaction fails" do
      user = create(:user, quick_donate_trigger_id: 'ORIGINAL')
      params = {:donation => attributes_for(:donation, :card_number => PaymentGateways::CARD_FAILURE)}
      @ask.update_action_attributes_and_validate(params)
      @ask.take_action(user, @page, nil, params)
      user.reload
      user.quick_donate_trigger_id.should == 'ORIGINAL'
    end

    it "should NOT update the user when processing a quick donation" do
      user_previously_updated = 1.hour.ago
      original_donation = create(:donation, trigger_id: 'ORIGINAL_TRIGGER_ID')
      user = create(:user, updated_at: user_previously_updated, quick_donate_trigger_id: 'ORIGINAL_TRIGGER_ID')
      params = {:donation => attributes_for(:donation, user: user, :quick_donation => '1'), user: {email: user.email}}
      @ask.update_action_attributes_and_validate(params)
      @ask.take_action(user, @page, nil, params, authenticated_for_quick_donate: true)
      user.reload
      user.updated_at.to_s.should == user_previously_updated.to_s
    end
    
    context "cc_logging enabled" do
      before :each do
        Setting.stub(:[]).with(:use_cc_logging).and_return('true')
        Setting.stub(:[]).with(:use_fraud_guard).and_return('false')
        Setting.stub(:[]).with('gateway1_percentage').and_return(100)
      end

      context "transaction success" do
        it "should process the donation and return success" do
          donation_params = {:donation => attributes_for(:donation, :card_number => PaymentGateways::CARD_SUCCESS)}
          @ask.update_action_attributes_and_validate(donation_params)
          @ask.take_action(@user, @page, @email, donation_params).should == true
          @ask.donation.user.should == @user
          @ask.donation.email.should == @email
          @ask.donation.transactions.first.should be_successful
        end
      end

      context "transaction failure" do
        it "should still return 'success'" do
          DonationService.any_instance.stub(:process!).and_return(false)
          @ask.should_not_receive(:notify_user)
          donation_params = {:donation => attributes_for(:donation, :card_number => PaymentGateways::CARD_SUCCESS)}
          @ask.update_action_attributes_and_validate(donation_params)
          @ask.take_action(@user, @page, @email, donation_params).should == true
        end
      end

      context "transaction raises exception" do
        it "should still return 'success'" do
          DonationService.any_instance.stub(:process!) { raise ActiveMerchant::ResponseError.new(502) }
          @ask.should_not_receive(:notify_user)
          @ask.should_receive(:notify_email)
          donation_params = {:donation => attributes_for(:donation, :card_number => PaymentGateways::CARD_SUCCESS)}
          @ask.update_action_attributes_and_validate(donation_params)
          @ask.take_action(@user, @page, @email, donation_params).should == true
        end
      end
    end
  end

  describe "tracking total amount raised" do
    before(:each) do
      @ask = create(:donation_module)
      @donation_101 = create(:donation, :content_module => @ask)
      @donation_215 = create(:donation, :content_module => @ask)

      @donation_101.transactions.create!(:amount_in_cents => 101, :successful => true)
      @donation_215.transactions.create!(:amount_in_cents => 215, :successful => true)
    end

    it "totals all the successful transactions" do
      @ask.amount_raised_in_cents.should == 316
    end

    it "converts cents to dollars" do
      @ask.amount_raised_in_dollars.should == 3.16
    end

    it "ignores failed transactions" do
      @donation_101.transactions.create!(:amount_in_cents => 1000, :successful => false)
      @ask.amount_raised_in_cents.should == 316
    end

    it "subtracts successful refunds" do
      refunded = @donation_101.transactions.first
      refunded.update_attributes!(:refunded => true)
      @donation_101.transactions.create!(:successful => true, :refund_of => refunded, :amount_in_cents => refunded.amount_in_cents)
      @ask.amount_raised_in_cents.should == 215
    end

    it "ignores failed refunds" do
      refunded = @donation_101.transactions.first
      @donation_101.transactions.create!(:successful => false, :refund_of => refunded, :amount_in_cents => refunded.amount_in_cents)
      @ask.amount_raised_in_cents.should == 316
    end
  end

  describe "for_a_future_recurring_payment?" do
    it "is false when commence_donation_at is blank" do
      ask = create(:donation_module, commence_donation_at: "")
      ask.should_not be_for_a_future_recurring_payment
    end
    it "is false when commence_donation_at is past" do
      ask = create(:donation_module, commence_donation_at: "01-01-2000")
      ask.should_not be_for_a_future_recurring_payment
    end
    it "is true when commence_donation_at is future" do
      Timecop.freeze(2012, 5, 20) do
        ask = create(:donation_module, commence_donation_at: "01-01-2025")
        ask.should be_for_a_future_recurring_payment
      end
    end
    it "is false when commence_donation_at is future" do
      Timecop.freeze(2012, 5, 20) do
        ask = create(:donation_module, commence_donation_at: "01-01-2025")
        ask.should be_for_a_future_recurring_payment
      end
    end
  end

  describe "commence_donation_at_date" do
    it "should return date prepresented by commence_donation_at" do
      date = Date.today
      ask = create(:donation_module, commence_donation_at: date.to_s)
      ask.commence_donation_at_date.should == date
    end
  end

  describe "providing user" do
    let!(:ask) { create(:donation_module, session: session, cookies: cookies) }
    let!(:user) { create(:user, quick_donate_trigger_id: 'TRIGGER_ID') }
    let!(:original_donation) { create(:donation, trigger_id: 'TRIGGER_ID') }

    context "multistep" do
      it "no cookie does not identify user" do
        ask.identifies_user?.should be false
        ask.identified_user.should be false
        ask.last_quick_donation.should be false
      end

      it "cookie identifies user" do
        set_quick_donate_user_id(user.id)
        ask.identifies_user?.should be_truthy
        ask.identified_user.should == user
        ask.last_quick_donation.should == original_donation
      end
    end
  end

  describe '#update_action_attributes_and_validate' do
    before do
      @ask = create(:donation_module, session: session)
    end
    context 'validate donation' do
      it 'returns true if donation is valid' do
        params = {:donation => attributes_for(:donation)}

        @ask.update_action_attributes_and_validate(params).should be true
      end

      it 'returns false if donation is invalid' do
        invalid_donation_params = {:donation => attributes_for(:donation, :card_expiry_year => "")}

        @ask.update_action_attributes_and_validate(invalid_donation_params).should be false
      end
    end

    context 'validate custom amount' do
      it 'should be valid for numerical value' do
        params = {:donation => attributes_for(:donation, :amount_in_dollars => "other", :custom_amount_in_dollars => "15")}
        @ask.update_action_attributes_and_validate(params).should be true
      end

      it 'should be valid for dollar value' do
        params = {:donation => attributes_for(:donation, :amount_in_dollars => "other", :custom_amount_in_dollars => "$15")}
        @ask.update_action_attributes_and_validate(params).should be true
      end

      it 'should be invalid for empty value' do
        params = {:donation => attributes_for(:donation, :amount_in_dollars => "other", :custom_amount_in_dollars => "")}
        @ask.update_action_attributes_and_validate(params).should be false
      end

      it 'should be invalid for zero value' do
        params = {:donation => attributes_for(:donation, :amount_in_dollars => "other", :custom_amount_in_dollars => "0.0")}
        @ask.update_action_attributes_and_validate(params).should be false
      end

      it 'should be invalid for range' do
        params = {:donation => attributes_for(:donation, :amount_in_dollars => "other", :custom_amount_in_dollars => "15-35")}
        @ask.update_action_attributes_and_validate(params).should be false
      end

      it 'should be invalid for text' do
        params = {:donation => attributes_for(:donation, :amount_in_dollars => "other", :custom_amount_in_dollars => "abcd")}
        @ask.update_action_attributes_and_validate(params).should be false
      end

      it 'should be valid for numerical value with spaces only' do
        params = {:donation => attributes_for(:donation, :amount_in_dollars => "other", :custom_amount_in_dollars => "   1    ")}
        @ask.update_action_attributes_and_validate(params).should be true
      end
    end

    context 'with quickdonate' do

      include QuickdonateHelper

      let(:user) { create(:user, quick_donate_trigger_id: 'TRIGGER_ID') }
      let(:page) { create(:page_with_parent) }
      let(:params) {{ donation: attributes_for(:donation, user: user, quick_donation: '1'),
                      user: {email: user.email} }}
      let!(:original_donation) { create(:donation, trigger_id: 'TRIGGER_ID')
      }

      it 'is invalid if correct quickdonate user id not in cookies' do
        @ask.update_action_attributes_and_validate(params).should be true
        @ask.cookies = cookies
        @ask.take_action(user, page, nil, params).should be false
        @ask.donation.errors.messages[:user].should == ['does not have payment details saved on this device']
      end

      it 'is valid if correct quickdonate user id in cookies' do
        @ask.update_action_attributes_and_validate(params).should be true
        cookies.signed[:quick_donate_user_id] = user.id
        @ask.cookies = cookies
        @ask.take_action(user, page, nil, params).should be true
      end

    end
  end

  describe '#if_trackable_donation_made' do
    context 'with a successful donation' do
      let!(:user){ create(:user, first_name: 'James', last_name: 'Test') }
      let!(:page){ create(:page_with_parent, :required_user_details => {:first_name => :required}) }
      let!(:ask){ create(:donation_module) }
      let!(:amount_donated_in_cents){ 3000 }
      let!(:amount_donated){ amount_donated_in_cents / 100 }
      let!(:donation_params){
        {
          donation: { payment_method: 'credit_card', amount_in_dollars: amount_donated, name_on_card: 'test', card_number: '1', card_cvv: '111', card_expiry_month: '01', card_expiry_year: '2050' }
        }
      }
      before{ Setting.stub(:[]).with(:use_cc_logging).and_return('true') }
      before{ Setting.stub(:[]).with(:use_fraud_guard).and_return('false') }
      before{ Setting.stub(:[]).with('gateway1_percentage').and_return(100) }
      before do
        ask.cookies = cookies
        ask.update_action_attributes_and_validate(donation_params)
        ask.take_action(user, page, nil, donation_params).should be true
      end

      it 'should call the passed block with the donation amount in cents and the user' do
        expect{ |b| ask.if_trackable_donation_made(&b) }.to yield_with_args(amount_donated_in_cents, user, ask.donation)
      end
    end
  end

  describe "with an recurring donation module that wasn't created with eligible_for_personalised_donation_tests set by default" do
    subject {
      create(:donation_module, frequency_options: { 'one_off' => 'hidden', 'weekly' => 'default', 'monthly' => 'hidden', 'annual' => 'hidden' }, eligible_for_personalised_donation_tests: false)
    }
    it { should be_valid }
    its(:eligible_for_personalised_donation_tests?){ should be false }
    it "should initialize to false" do
      subject.reload
      subject.should_not be_eligible_for_personalised_donation_tests
    end
  end

  describe "with a newly created module" do
    subject{ create(:donation_module) }
    it { should be_valid }
    its(:eligible_for_personalised_donation_tests?){ should be true }

    it "should initialize a new record with eligible_for_personalised_donation_tests set to true" do
      DonationModule.new.should be_eligible_for_personalised_donation_tests
    end
  end
  
  describe "content module not eligible_for_personalised_donation_tests" do
    before :each do
      @user = create :user
      donation = create :donation, user: @user
      create :transaction, donation: donation, amount_in_cents: 5000
      @ask = build_donation_module(personalised_amounts: "1500, 300*, 140*, 100, 70*, 50, 30", personalised_default_amount: "70")
      @ask.eligible_for_personalised_donation_tests = nil
      @ask.save!
      @ask.donations << donation
    end
    
    it 'should show static personalised values' do
      @ask.amounts_list(@user).should == %w(1500 300* 140* 100 70* 50 30)
      @ask.default_amount_in_dollars(@user).should == "70"
    end
    
    it 'should show actual personalised amounts if provided explicity and not default' do
      @ask.update_attributes! :personalised_amounts => "800*, 200*, 70*, 40, 10", :personalised_default_amount => "200"
      @ask.amounts_list(@user).should == %w(800* 200* 70* 40 10)
      @ask.default_amount_in_dollars(@user).should == "200"
    end

    it 'should only show static amounts if it is a recurring ask' do
      @ask.frequency_options = {'weekly' => 'default'}
      @ask.save!
      @ask.amounts_list(@user).should == ["100", " 50*", " 30*", " 12*", " 5", " 3"]
    end
  end

  describe "personalised amounts ab test" do
    let(:ask){ create(:donation_module) }
    let!(:user){ @user = create :user }
    let!(:donation){ create(:donation, created_at: 30.days.ago, user: user) }
    let!(:transaction){ create(:transaction, donation: donation, amount_in_cents: 5200) }
    before :each do
      ask.cookies = cookies
      ask.donations << donation
      @experiment = Vanity.playground.experiment(:personalised_amounts_v4)
      @experiment.identify { |controller| 1 }
    end

    describe "with a user without a HPD" do
      let(:ask){ create(:donation_module) }

      it 'should use suggested amounts' do
        ask.amounts_list(create(:user)).should == ask.suggested_amounts_list(false)
        ask.default_amount_in_dollars(create(:user)).should == "12"
      end

      it 'should set the post action data' do
        ask.pre_action_data_for_logger({user: create(:user)}).should ==
          {:hpda=>nil, :amounts_list=>ask.suggested_amounts_list(false), use_fixed_amounts: false, :user_known=>true}
      end
    end

    describe "with :static option in A/B test" do
      before{ @experiment.chooses(:static) }

      it 'should show relative amounts' do
        ask.amounts_list(@user).should == DonationModule::DEFAULT_PERSONALISED_AMOUNTS.split(', ')
        ask.default_amount_in_dollars(@user).should == '70'
      end

      it 'should set the post action data' do
        ask.pre_action_data_for_logger({user: @user}).should ==
          {:hpda=>52, :amounts_list=>ask.amounts_list(@user), use_fixed_amounts: false, :user_known=>true}
      end
    end

    describe "with :relative option in A/B test" do
      before{ @experiment.chooses(:relative) }

      it 'should show static personalised values' do
        ask.amounts_list(@user).should == ["260*", "156", "104*", "73*", "65*"]
        ask.default_amount_in_dollars(@user).should == '73'
      end

      it 'should set the post action data' do
        ask.pre_action_data_for_logger({user: @user}).should ==
          {:hpda=>52, :amounts_list=>ask.amounts_list(@user), use_fixed_amounts: false, :user_known=>true}
      end
    end

    describe "with :relative_with_adjustments option in A/B test" do
      before{ @experiment.chooses(:relative_with_adjustments) }

      it 'should show personalised values' do
        ask.amounts_list(@user).should == ["260*", "156", "104*", "73*", "65*"]
        ask.default_amount_in_dollars(@user).should == '73'
      end

      context "with an amount less than $15" do
        before do
          transaction.amount_in_cents = 1000
          transaction.save!
        end
        it 'should show personalised values boosted by 20%' do
          ask.amounts_list(@user).should == ["50*", "32", "22*", "16*", "15*"]
          ask.default_amount_in_dollars(@user).should == '16'
        end
      end

      context "with an amount over than $15 and have donated in the last 21 days" do
        before do
          donation.created_at = Date.today
          donation.save!
        end
        it 'should show personalised values reduced by 20%' do
          ask.amounts_list(@user).should == ["156*", "104", "83*", "62*", "52*"]
          ask.default_amount_in_dollars(@user).should == '62'
        end
      end
    end

    describe "with :relative_with_average_check option in A/B test" do
      before{ @experiment.chooses(:relative_with_average_check) }

      it 'should show personalised values' do
        ask.amounts_list(@user).should == ["260*", "156", "104*", "73*", "65*"]
        ask.default_amount_in_dollars(@user).should == '73'
      end

      context "when their average is less than half of their HPD" do
        let!(:low_donation){ create(:donation, user: user, amount_in_cents: 1000) }
        let!(:low_transation){ create(:transaction, donation: low_donation, amount_in_cents: low_donation.amount_in_cents) }
        let!(:another_low_donation){ create(:donation, user: user, amount_in_cents: 1000) }
        let!(:another_low_transation){ create(:transaction, donation: another_low_donation, amount_in_cents: another_low_donation.amount_in_cents) }
        it 'should show reduced personalised values' do
          ask.amounts_list(@user).should == ["104*", "73", "62*", "52*", "47*"]
          ask.default_amount_in_dollars(@user).should == '52'
        end
      end
    end
  end

  describe 'amounts shown on mobile experiment' do
    subject { create(:donation_module) }
    it 'shows existing amounts by default' do
      expect(subject.amounts_list(nil)).to eq(["100", " 50*", " 30*", " 12*", " 5", " 3"])
    end
    context 'when in the treatment group' do
      before { @mobile_amounts_exp.chooses(:all) }
      it 'shows all amounts' do
        expect(subject.amounts_list(nil)).to eq(["100*", "50*", "30*", "12*", "5*", "3*"])
      end
    end
  end

end
