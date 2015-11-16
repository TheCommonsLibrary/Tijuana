require File.dirname(__FILE__) + '/../spec_helper.rb'

describe Donation do
  def create_donation_module_with_custom_item_with_select_options(options)
    create(:donation_module, custom_fields: {form_fields: [name: 'item', type: 'select', options: options]})
  end
  private :create_donation_module_with_custom_item_with_select_options

  describe "amounts" do
    it "converts cents into dollars" do
      donation = create(:donation)

      donation.amount_in_cents = 235
      donation.amount_in_dollars.should == 2.35

      donation.amount_in_dollars = 10.50
      donation.amount_in_cents.should == 1050

      donation.amount_in_dollars = 10.501
      donation.amount_in_cents.should == 1050

      donation.amount_in_dollars = "99"
      donation.amount_in_cents.should == 9900
    end

    it "uses custom amount if amount_in_dollars is unspecified" do
      donation = create(:donation)

      donation.custom_amount_in_dollars = "12.41"
      donation.amount_in_dollars = "1000"
      donation.custom_amount_in_dollars.should == "12.41"
      donation.amount_in_dollars.should == 1000.0

      donation.custom_amount_in_dollars = "$12.41"
      donation.amount_in_dollars.should == 12.41

      donation.amount_in_dollars = "other"
      donation.custom_amount_in_dollars = "12.41"
      donation.custom_amount_in_dollars.should == "12.41"
      donation.amount_in_dollars.should == 12.41

      donation.custom_amount_in_dollars = ""
      donation.amount_in_dollars = "other"
      donation.custom_amount_in_dollars.should == ""
      donation.amount_in_dollars.should == 0.0
    end
  end

  describe "validation" do

    describe "#validate_credit_card_indentifiers" do
      it 'should add error if month is invalid' do
        donation = create(:donation)
        donation.card_expiry_month = 'w'
        donation.validate_credit_card_indentifiers
        donation.errors[:card_expiry_month].should include '^Credit card expiry month is invalid'
      end

      it 'should add error if year is invalid' do
        donation = create(:donation)
        donation.card_expiry_year = 'w'
        donation.validate_credit_card_indentifiers
        donation.errors[:card_expiry_year].should include '^Credit card expiry year is invalid'
      end

      it 'should add error if the last four digits is invalid' do
        donation = create(:donation)
        donation.card_last_four_digits = 'w'
        donation.validate_credit_card_indentifiers
        donation.errors[:card_last_four_digits].should include '^Credit card last four digits is invalid'
      end

      it 'should not add any errors for valid attributes' do
        donation = create(:donation)
        donation.card_last_four_digits = 1234
        donation.validate_credit_card_indentifiers
        donation.errors.size.should == 0
      end
    end

    context "custom fields" do
      it "must have custom field if it is required" do
        dm = create(:donation_module, custom_fields: {
            form_fields: [name: 'field_item', required: true]
        })
        donation = build(:donation, content_module: dm)
        donation.should_not be_valid
        donation.errors.full_messages.first.should == 'Field item is required'
      end
      it "may have blank custom field if it is not required" do
        dm = create(:donation_module, custom_fields: {
            form_fields: [name: 'field_item', required: false]
        })
        donation = build(:donation, content_module: dm)
        donation.should be_valid
      end
      context "with minimum donation" do
        before :each do
          @dm = create_donation_module_with_custom_item_with_select_options([
             {text: "Option 1", value: 'MINIMUM_30', minimum_donation: 30},
             {text: "Option 2", value: 'MINIMUM_15', minimum_donation: 15},
             {text: "Option 3", value: 'MINIMUM_27.50', minimum_donation: 27.50}
          ])
        end
        it "is invalid if donation amount is less than minimum" do
          donation = build(:donation, amount_in_cents: 2999, content_module: @dm)
          donation.item = 'MINIMUM_30'
          donation.should_not be_valid
          donation.errors.full_messages.first.should == 'Item ^Minimum donation amount is $30.00'
        end
        it 'should show two decimal places for partial dollar amounts' do
          donation = build(:donation, amount_in_cents: 1, content_module: @dm)
          donation.item = 'MINIMUM_27.50'
          donation.should_not be_valid
          donation.errors.full_messages.first.should == 'Item ^Minimum donation amount is $27.50'
        end
        it "is valid if donation amount is equal to minimum" do
          donation = build(:donation, amount_in_cents: 1500, content_module: @dm)
          donation.item = 'MINIMUM_15'
          donation.should be_valid
        end
      end
      context "with options requiring another field" do
        before :each do
          @dm = create_donation_module_with_custom_item_with_select_options([
            {text: "Option 1", value: 'REQUIRES_CHEQUE', requires: :cheque_number},
            {text: "Option 2", value: 'DOES_NOT_REQUIRE_CHEQUE'}
          ])
        end
        it "is not valid if selected option requires another field that is not present" do
          donation = build(:donation, cheque_number: nil, content_module: @dm)
          donation.item = 'REQUIRES_CHEQUE'
          donation.should_not be_valid
          donation.errors.full_messages.first.should == 'Cheque number is required'
        end
        it "is valid if selected option requires another field that is present" do
          donation = build(:donation, cheque_number: '1234', content_module: @dm)
          donation.item = 'REQUIRES_CHEQUE'
          donation.should be_valid
        end
        it "is valid if selected option does not require another field" do
          donation = build(:donation, cheque_number: nil, content_module: @dm)
          donation.item = 'DOES_NOT_REQUIRE_CHEQUE'
          donation.should be_valid
        end
      end
      it "is not valid if value is not a legal option" do
        dm = create_donation_module_with_custom_item_with_select_options([
            {text: "Option 1", value: 'OPTION_1'},
            {text: "Option 2", value: 'OPTION_2'}
        ])
        donation = build(:donation, amount_in_cents: 1500, content_module: dm)
        donation.item = 'OPTION_ILLEGAL'
        donation.should_not be_valid
        donation.errors.full_messages.first.should == 'Item is not one of the supplied options'
      end
    end

    def create_and_validate_donation(attrs={})
      donation = build(:donation)
      donation.attributes = attrs
      donation.valid?
      donation
    end
    private :create_and_validate_donation

    it "must have a positive amount_in_dollars" do
      create_and_validate_donation(:amount_in_dollars => "10.99").should be_valid
      create_and_validate_donation(:amount_in_dollars => "0.0").should_not be_valid
      create_and_validate_donation(:amount_in_dollars => "Ten").should_not be_valid
    end

    it "must have a positive custom_amount_in_dollars if specified" do
      create_and_validate_donation(:custom_amount_in_dollars => "10.10", :amount_in_dollars => "other").should be_valid
      create_and_validate_donation(:custom_amount_in_dollars => "0.0", :amount_in_dollars => "other").should_not be_valid
      create_and_validate_donation(:custom_amount_in_dollars => "", :amount_in_dollars => "other").should_not be_valid
      create_and_validate_donation(:custom_amount_in_dollars => "something else", :amount_in_dollars => "2000").should be_valid
      create_and_validate_donation(:custom_amount_in_dollars => "something else", :amount_in_dollars => "other").should_not be_valid
    end

    it "should handle a dollar sign in the custom_amount_in_dollars if specified" do
      create_and_validate_donation(:custom_amount_in_dollars => "$10.10", :amount_in_dollars => "other").should be_valid
    end

    describe "credit card" do

      context 'payment_method' do
        let(:donation) { build(:donation)}

        context 'payment_method set to :credit card' do
          it 'should trigger card validation' do
            donation.attributes = {payment_method: :credit_card}
            donation.should_receive(:validate_card_date).and_return(true)
            donation.valid?
          end
        end

        context 'payment_method set to :credit card' do
          it 'should trigger card validation' do
            donation.attributes = {payment_method: 'credit_card'}
            donation.should_receive(:validate_card_date).and_return(true)
            donation.valid?
          end
        end
      end

      it "must have an expiry year" do
        create_and_validate_donation(:card_expiry_year => "2099").should be_valid
        create_and_validate_donation(:card_expiry_year => "99").should be_valid

        create_and_validate_donation(:card_expiry_year => "9").should_not be_valid
        create_and_validate_donation(:card_expiry_year => "Eh?").should_not be_valid
      end

      it "must have an expiry month between 1 and 12" do
        create_and_validate_donation(:card_expiry_month => 12).should be_valid
        create_and_validate_donation(:card_expiry_month => 13).should_not be_valid
        create_and_validate_donation(:card_expiry_month => 0).should_not be_valid
      end

      it "must have an expiry date in the future" do
        create_and_validate_donation(:card_expiry_year => Time.now.year, :card_expiry_month => Time.now.month).should be_valid
        create_and_validate_donation(:card_expiry_year => 1.month.ago.utc.year, :card_expiry_month => 1.month.ago.utc.month).should_not be_valid
      end

      it "must have a numeric CVV between 3 and 4 digits" do
        create_and_validate_donation(:card_cvv => "123").should be_valid
        create_and_validate_donation(:card_cvv => "1234").should be_valid
        create_and_validate_donation(:card_cvv => "12345").should_not be_valid
        create_and_validate_donation(:card_cvv => "12").should_not be_valid
        create_and_validate_donation(:card_cvv => "ABC").should_not be_valid
        create_and_validate_donation(:card_cvv => "").should_not be_valid
      end

      it "should mention that card number needs to be entered" do
        donation = build(:donation, :card_number => "XXX", :card_cvv => "123")
        donation.valid?.should be false
        donation.errors[:card_number][0].should match("and cvv needs to be entered. We don't retain your card number and cvv for security reasons. Please re-enter the card number and cvv before submitting.")
      end

      it "can have blank credit card details if it is a quick_donation" do
        user_with_quickdonate_trigger = create(:user, quick_donate_trigger_id: 'SOME_TRIGGER_ID')
        create_and_validate_donation(
            user: user_with_quickdonate_trigger,
            quick_donation: '1',
            card_expiry_year: "",
            card_expiry_month:"",
            card_cvv: "",
            card_number: ""
        ).should be_valid
      end

      it "user must have quick_donate_trigger_id if it is a quick donate" do
        user_without_quickdonate_trigger = create(:user, quick_donate_trigger_id: '')
        donation = create_and_validate_donation(
            user: user_without_quickdonate_trigger,
            quick_donation: '1'
        )
        donation.should_not be_valid
        donation.errors[:user].first.should match 'must have saved payment details'
      end
    end
  end

  describe "scopes" do
    before :each do
      @inactive_card_name = 'inactive cardguy'
      create(:donation, active: false, name_on_card: @inactive_card_name)
      create(:donation, flagged_since: Time.now)
      create(:donation, frequency: "one_off")
      create(:donation, frequency: "weekly")
      create(:donation, flagged_since: nil)
      create(:donation, last_donated_at: nil, flagged_since: Time.now)
      create(:donation, flagged_since: Time.now, assigned_to: "Rich")
      create(:donation, flagged_since: Time.now)
      create(:donation, dismissed_at: Time.now)
    end

    it "should retrieve only active donations" do
      Donation.active.each do |donation|
        donation.name_on_card.should_not == @inactive_card_name
      end
    end

    it "should retrieve only flagged donations" do
      Donation.flagged.each do |donation|
        donation.flagged_since.should_not be_nil
      end
    end

    it "should retrieve recurring donations" do
      Donation.recurring.each do |donation|
        donation.frequency.should_not == "one_off"
      end
    end

    it "should retrieve unflagged donaations" do
      Donation.unflagged.each do |donation|
        donation.flagged_since.should be_nil
      end
    end

    it "should retrieve only failed new donations" do
      Donation.failed_new_donation do |donation|
        donation.last_donated_at.should be_nil
        donation.flagged_since.should_not be_nil
      end
    end

    it "should retrieve only the assigned donations" do
      Donation.assigned do |donation|
        donation.flagged_since.should_not be_nil
        donation.assigned_to.should_not be_nil
      end
    end

    it "should retrieve only the unassigned donations" do
      Donation.unassigned do |donation|
        donation.flagged_since.should_not be_nil
        donation.assigned_to.should be_nil
      end
    end

    it "should retrieve only dismissed donations" do
      Donation.not_dismissed do |donation|
        donation.dismissed_at.should_not be_nil
      end
    end

    it "should retrieve out of date one off donations that have trigger id where a user has not enrolled in quick donate" do
      user_not_enrolled_in_qd = create(:user)
      user_enrolled_in_qd = create(:user, quick_donate_trigger_id: "some trigger id")
      donation_1 = create(:donation, user: user_not_enrolled_in_qd, trigger_id: "some trigger id", last_donated_at: 2.months.ago)
      donation_2 = create(:donation, user: user_not_enrolled_in_qd, trigger_id: "some trigger id", last_donated_at: 6.days.ago)
      donation_3 = create(:donation, user: user_enrolled_in_qd, trigger_id: "some trigger id", last_donated_at: 2.months.ago)

      out_of_date_donations = Donation.one_off_out_of_date_donation_with_trigger_id(1.week.ago)
      out_of_date_donations.length.should == 1
      out_of_date_donations.first.should == donation_1
    end

  end

  describe "failed new donations" do
    it "should only display new failed donations within 2 weeks with the newest flagged donations first" do
      donation_1 = create(:donation, last_donated_at: nil, flagged_since: 3.weeks.ago, created_at: 3.weeks.ago)
      donation_2 = create(:donation, last_donated_at: nil, flagged_since: 1.week.ago, created_at: 1.week.ago)
      donation_3 = create(:donation, last_donated_at: nil, flagged_since: Time.now, created_at: Time.now)

      Donation.failed_new_donation.size.should == 2
      Donation.failed_new_donation.first.id.should == donation_3.id
      Donation.failed_new_donation.last.id.should == donation_2.id
    end
  end

  describe "failed recurring donations" do
    it "should display failed recurring donations in with the newest flagged donations first" do
      donation_1 = create(:donation, last_donated_at: nil, frequency: "weekly", flagged_since: 3.weeks.ago, flagged_because: 'oops', created_at: 3.weeks.ago)
      donation_2 = create(:donation, last_donated_at: nil, frequency: "weekly", flagged_since: 1.week.ago, flagged_because: 'its not you its me', created_at: 1.week.ago)
      one_off = create(:donation, last_donated_at: nil, flagged_since: Time.now, flagged_because: 'something went wrong')

      Donation.failed_recurring_donations.size.should == 2
      Donation.failed_recurring_donations.first.id.should == donation_2.id
      Donation.failed_recurring_donations.last.id.should == donation_1.id
    end
  end
  
  describe "credit card number formatting" do
    it "Removes all non-numeric characters to keep SecurePay happy" do
      donation = build(:donation)
      donation.card_number = "4111-1111.1111 1111"
      donation.send(:credit_card).number.should == "4111111111111111"
    end
  end

  describe "credit card security" do
    it "only persists the last 4 digits of the number" do
      donation = build(:donation)
      donation.card_number = "4111111111111111"
      donation.save!
      donation = Donation.find(donation.id)
      donation.card_number.should == nil
      donation.card_last_four_digits.should == "1111"
    end

    it "should update the donation's card' last 4 digits" do
      donation = build(:donation)
      donation.card_number = "4111111111111111"
      donation.save!

      donation = Donation.find(donation.id)
      donation.card_last_four_digits.should == "1111"

      donation.card_number = "4242424242424242"
      donation.card_cvv = "123"
      donation.save!

      donation = Donation.find(donation.id)
      donation.card_last_four_digits.should == "4242"
    end

    it "does not persist the CVV" do
      donation = build(:donation)
      donation.card_cvv = "123"
      donation.save!
      donation = Donation.find(donation.id)
      donation.card_cvv.should == nil
    end
  end

  describe "#made_to" do
    before(:each) do
      donate_ps = PageSequence.static.create(:name => "Donate")
      @page = create(:page, :page_sequence => donate_ps)
    end

    it "should return the campaign the donation was made to or the string 'GetUp' on one off campaigns" do
      donation = create(:donation, :card_number => PaymentGateways::CARD_SUCCESS, :frequency => "one_off")
      donation1 = create(:donation, :card_number => PaymentGateways::CARD_SUCCESS, :frequency => "one_off", :page => @page)

      donation.made_to.should eql "Dummy Campaign Name"
      donation1.made_to.should eql "GetUp!"
    end

    it "should return Core Member on all recurring donations" do
      donation = create(:donation, :card_number => PaymentGateways::CARD_SUCCESS, :frequency => "weekly")
      donation1 = create(:donation, :card_number => PaymentGateways::CARD_SUCCESS, :frequency => "monthly", :page => @page)

      donation.made_to.should eql "Core Member"
      donation1.made_to.should eql "Core Member"
    end

  end

  describe ".find_page_id_for_offline_donation_campaign" do

    context "with page for campaign" do
      before :each do
        @campaign = create(:campaign)
        @page_sequence = create(:page_sequence, :campaign => @campaign)

        @donation_page = create(:page, :id => 10, :page_sequence => @page_sequence)
        @petition_page = create(:page, :id => 11, :page_sequence => @page_sequence, :name => "petition")

        @donation_module = create(:donation_module)
        @petition_module = create(:petition_module)

        ContentModuleLink.create!(:page => @donation_page, :content_module => @donation_module)
        ContentModuleLink.create!(:page => @petition_page, :content_module => @petition_module)
      end

      it "should find a page_id with donation module for given offline donation campaign" do
        Donation.find_page_id_for_offline_donation_campaign(@campaign.id).should eql @donation_page.id
      end

      it "should not find a within a deleted page sequence" do
        @page_sequence.destroy
        Donation.find_page_id_for_offline_donation_campaign(@campaign.id).should be_nil
      end
      it "should not find a deleted page" do
        @donation_page.destroy
        Donation.find_page_id_for_offline_donation_campaign(@campaign.id).should be_nil
      end
      it "should not find a page with a deleted donation module" do
        @donation_module.destroy
        Donation.find_page_id_for_offline_donation_campaign(@campaign.id).should be_nil
      end
    end

    it "should assign to global donation page_id if no campaign is selected" do
      global_donation_page = create(:page, :id => 1, :page_sequence => create(:static_page_sequence, :name => "Donate"))
      donation_module = create(:donation_module)
      ContentModuleLink.create!(:page => global_donation_page, :content_module => donation_module)

      Donation.find_page_id_for_offline_donation_campaign("").should eql global_donation_page.id
    end
  end

  describe '#set_card_type' do
    before do
      @donation = Donation.new
    end
    it 'should return nil when card number is empty' do
      @donation.card_number = nil
      @donation.set_card_type.should be_nil
    end

    context 'visa number' do
      it 'should set card type to visa' do
        @donation.card_number = '4444444444444448'
        @donation.set_card_type.should == :visa

        @donation.card_number = '4114360123456785'
        @donation.set_card_type.should == :visa

        @donation.card_number = '4110 1441 1014 4115'
        @donation.set_card_type.should == :visa

        @donation.card_number = '4110144110144'
        @donation.set_card_type.should == :visa
      end
    end

    context 'mastercard number' do
      it 'should set card type to mastercard' do
        @donation.card_number = '5500 0055 5555 5559'
        @donation.set_card_type.should == :mastercard

        @donation.card_number = '5111005111051128'
        @donation.set_card_type.should == :mastercard

        @donation.card_number = '5478050000000007'
        @donation.set_card_type.should == :mastercard
      end
    end

    context 'american express number' do
      it 'should set card type to american_express' do
        @donation.card_number = '3714 496353 98431'
        @donation.set_card_type.should == :american_express

        @donation.card_number = '343434343434343'
        @donation.set_card_type.should == :american_express
      end
    end

    context 'other card numbers like JCB, Diners, etc.' do
      it 'should set card type to nil' do
        @donation.card_number = '36438936438936'
        @donation.set_card_type.should be_nil

        @donation.card_number = '3566003566003566'
        @donation.set_card_type.should be_nil
      end
    end

    it 'should save donation with correct card type' do
      donation = build(:donation)
      donation.card_number = "5500005555555559"
      donation.save!
      donation.card_type.should == 'mastercard'

      donation.card_number = '36438936438936'
      donation.save!
      donation.card_type.should be_nil
    end
  end

  describe "can_be_used_for_quickdonate?" do
    it "is true for credit card donations" do
      page = create(:page_with_parent)
      donation = create(:donation, payment_method: 'credit_card', page: page)
      donation.can_be_used_for_quickdonate_for_page?(page).should be true
    end
    it "is false for non credit card donations" do
      page = create(:page_with_parent)
      donation = create(:donation, payment_method: 'paypal', page: page)
      donation.can_be_used_for_quickdonate_for_page?(page).should be false
    end
    it "is false for donation for another page" do
      another_page = create(:page_with_parent)
      donation = create(:donation, payment_method: 'paypal')
      donation.can_be_used_for_quickdonate_for_page?(another_page).should be false
    end
  end

  describe "use_for_quickdonate" do
    it "sets trigger as quickdonate trigger on user" do
      user = create(:user)
      donation = create(:donation, user: user, trigger_id: 'THE TRIGGER ID')
      donation.use_for_quickdonate
      user.reload
      user.quick_donate_trigger_id.should == donation.trigger_id
    end
  end

  describe "copy_credit_card_details for quick donation" do
    before :each do
      Timecop.travel '25 Dec 2014' # freeze so credit card not expired
    end

    after :each do
      Timecop.return
    end

    
    let :quick_donate_user do create(:user, quick_donate_trigger_id: 'TRIGGER_ID') end
    let :original do create(:donation, trigger_id: 'TRIGGER_ID', payment_method: 'credit_card', card_number: '4444444444444448', card_expiry_month: '12', card_expiry_year: '14', name_on_card: 'Original Name') end
    let :copy do create(:donation, user: quick_donate_user, quick_donation: '1') end

    context 'when successful' do
      before :each do
        copy.copy_credit_card_details!(original)
      end

      it "should copy name on card" do
        copy.name_on_card.should == original.name_on_card
      end
      it "should copy card_expiry" do
        copy.card_expiry_month.should == original.card_expiry_month
        copy.card_expiry_year.should == original.card_expiry_year
      end
      it "should copy card type" do
        copy.card_type.should == original.card_type
      end
      it "should copy last four digits of card number" do
        copy.card_last_four_digits.should == original.card_last_four_digits
      end
    end

    it "raises an exception if donation is not quickdonate" do
      copy.quick_donation = '0'
      expect {
        copy.copy_credit_card_details!(original)
      }.to raise_error "Can only copy credit card details for quick donations"
    end
  end

  describe "update_allowed?" do
    context 'recent donation' do
      let :donation do create(:donation, created_at: 14.minutes.ago) end
      it "allows update if recent donation only has no transactions" do
        donation.should be_update_allowed
      end
      it "allows update if recent donation only has failed transactions" do
        create(:failed_transaction, donation: donation)
        donation.should be_update_allowed
      end
      it "denies update if recent donation has any successful transactions" do
        create(:failed_transaction, donation: donation)
        create(:transaction, donation: donation)
        donation.should_not be_update_allowed
      end
    end
    context 'old donation' do
      it "denies update" do
        donation = create(:donation, created_at: 15.minutes.ago)
        donation.should_not be_update_allowed
      end
    end
  end

  describe "has_successful_transaction_since" do
    let (:donation) { create(:donation, created_at: 1.week.ago) }
    it "should return true if there is a successful transaction since the time in the past" do
      create(:transaction, donation: donation, created_at: 6.days.ago, refunded: 0)
      create(:failed_transaction, donation: donation, created_at: 5.days.ago)
      create(:failed_transaction, donation: donation, created_at: 4.days.ago)

      donation.has_successful_transaction_since?(1.week.ago).should == true
      donation.has_successful_transaction_since?(4.days.ago).should == false
      donation.has_successful_transaction_since?(3.days.ago).should == false
    end
    it "should return false if there is a successful transaction but that transaction has been refunded" do
      create(:transaction, donation: donation, created_at: 6.days.ago, refunded: 1)
      create(:failed_transaction, donation: donation, created_at: 5.days.ago)
      create(:failed_transaction, donation: donation, created_at: 4.days.ago)

      donation.has_successful_transaction_since?(6.days.ago).should == false
      donation.has_successful_transaction_since?(4.days.ago).should == false
      donation.has_successful_transaction_since?(3.days.ago).should == false
    end
  end

  describe "has_successful_transaction" do
    let (:donation) { create(:donation, created_at: 1.week.ago) }
    it "should return true if there is a successful transaction" do
      create(:transaction, donation: donation, created_at: 6.days.ago, refunded: 0)
      create(:failed_transaction, donation: donation, created_at: 5.days.ago)
      create(:failed_transaction, donation: donation, created_at: 4.days.ago)

      donation.has_successful_transaction?.should == true
    end
    it "should return false if there is a successful transaction but that transaction has been refunded" do
      create(:transaction, donation: donation, created_at: 6.days.ago, refunded: 1)
      create(:failed_transaction, donation: donation, created_at: 5.days.ago)
      create(:failed_transaction, donation: donation, created_at: 4.days.ago)

      donation.has_successful_transaction?.should == false
    end
    it "should return false if there is no successful transaction" do
      create(:failed_transaction, donation: donation, created_at: 6.days.ago)
      create(:failed_transaction, donation: donation, created_at: 5.days.ago)
      create(:failed_transaction, donation: donation, created_at: 4.days.ago)

      donation.has_successful_transaction?.should == false
    end
  end

  describe "#can_update_anonymously?" do
    before { Timecop.travel(Time.local(2015, 11, 22)) }

    let!(:donation) { create(:donation, created_at: 1.week.ago, card_expiry_month: 1, card_expiry_year: 2016, flagged_since: nil) }

    it "should return true if flagged_since is not null" do
      donation.flagged_since = Time.local(2015, 04, 10)
      donation.can_update_anonymously?.should be_truthy
    end

    it "returns false if card isn't going to expire this month or next" do
      Timecop.travel(Time.local(2015, 11, 30))
      donation.can_update_anonymously?.should be false
    end

    it "returns true if card is going to expire this month or next" do
      Timecop.travel(Time.local(2015, 12, 01))
      donation.can_update_anonymously?.should be true
    end

    it "should return false if no failure email has been sent" do
      donation.can_update_anonymously?.should be false
    end

    it "should return true if there is failure email and no succesful transaction since that time" do
      SentTriggerEmail.create(user_id: donation.user.id, key: :donation_failing_email, triggered_by: donation)
      donation.can_update_anonymously?.should be true
    end

    it "should return false if there is failure email and has succesful transaction since that time" do
      SentTriggerEmail.create(user_id: donation.user.id, key: :donation_failing_email, triggered_by: donation, sent_date: 1.week.ago)
      create(:transaction, donation: donation, created_at: 6.days.ago)
      donation.can_update_anonymously?.should be false
    end
  end

  describe "#cancel" do
    before do
      @donation = create(:donation, :frequency => "monthly")
    end

    it "should mark the donation as inactive and record cancel reason and time" do
      Timecop.freeze(2016, 01, 01, 10, 00, 00) do
        @donation.cancel_recurring!('retired')

        @donation.reload.should_not be_active
        expect(@donation.cancel_reason).to eq('retired')
        expect(@donation.cancelled_at).to eq(Time.now)
      end
    end
  end

  describe "#card_supports_recurring_flag?" do
    context "with empty card_type" do
      let!(:donation){ create(:donation) }
      specify{ expect(donation.card_supports_recurring_flag?).to be_truthy }
    end

    context "with an amex" do
      let!(:donation){ create(:donation, card_number: '378734493671000') }
      specify{ expect(donation.card_supports_recurring_flag?).to be_falsey }
    end

    {visa: '4111111111111111', mastercard: '5500005555555559'}.each do |card_type, number|
      context "with an #{card_type}" do
        let!(:donation){ create(:donation, card_number: number) }
        specify{ expect(donation.card_supports_recurring_flag?).to be_truthy }
      end
    end
  end
end
