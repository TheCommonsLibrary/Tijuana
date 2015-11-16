require File.dirname(__FILE__) + "/scenario_helper.rb"

include ActionView::Helpers::NumberHelper
include LoginHelper
include OfflineDonationHelper

describe "Admin manages user transactions", type: :feature, js: true do

  before(:each) do
    User.create(email: 'mygetup@getup.org.au', password: 'password', is_admin: true)
  end

  describe "Non credit card transactions" do
    before(:each) do
      sign_in_as_admin
    end

    it "should show a message that it can't be refunded" do
      amount_in_dollars = 50.00
      donation = create(:donation, payment_method: :paypal, amount_in_cents: amount_in_dollars * 100)
      transaction = create(:transaction, amount_in_cents: amount_in_dollars * 100, donation: donation)

      visit admin_transactions_path
      fill_in 'query', with: amount_in_dollars
      click_button 'Search'

      page.should have_content(donation.amount_in_dollars)

      click_link 'Manage'

      page.should have_content("Only credit card payments can be refunded through this interface.")
    end
  end

  describe "Creating a new offline donation" do
    let(:umbrella_user) { create(:user) }
    let(:user) { create(:user) }

    let(:donation_page) { create(:page_with_parent) }
    let(:donation_module) { create(:donation_module) }

    let(:amount_in_dollars) { 33.33 }

    before(:each) do
      MemberCountCalculator.init
      User.stub(:umbrella_user).and_return(umbrella_user)
      link = create(:content_module_link, page: donation_page, content_module: donation_module, layout_container: :sidebar)
      donation = create(:donation, payment_method: :paypal, amount_in_cents: amount_in_dollars * 100, :page_id => donation_page.id)
      sign_in_as_admin
    end

    it "should be able to make a donation from an existing user" do
      create_offline_donation(user, donation_page, amount_in_dollars)

      click_button 'Create donation'

      URI.parse(page.driver.current_url).path.should == admin_transactions_path
      page.should have_content(amount_in_dollars)
    end

    it "should make a donation from a non-existant user" do
      create_offline_donation(user, donation_page, amount_in_dollars)

      check 'umbrella_user'

      click_button 'Create donation'

      URI.parse(page.driver.current_url).path.should == admin_transactions_path
      page.should have_content(amount_in_dollars)
    end
  end

  describe "Credit card transactions (using gateway - integration style!)" do
    let(:amount_in_dollars) { 5000 }
    let(:credit_card_donation_options) { {
        card_type: "visa",
        card_number: "5119 5800 0409 3975",
        name_on_card: "TOM MANN",
        card_expiry_month: "06",
        card_expiry_year: "2022",
        card_cvv: "904",
        payment_method: :credit_card,
        amount_in_cents: amount_in_dollars * 100
    } }


    before(:all) do
      ENV["USE_PROVIDER_GATEWAY"] = 'true'
    end

    after(:all) do
      ENV["USE_PROVIDER_GATEWAY"] = ''
    end

    before(:each) do
      sign_in_as_admin
      @service = DonationService.new
    end

    # payment gateway test: donate once off and refund donation
    it "should refund credit card transactions" do
      donation = create(:donation, credit_card_donation_options)
      @service.process!(donation, :ip => "75.101.145.87")

      find_transactions(donation)
      
      page.should have_content "SecurePay"
      click_link 'Manage'

      fill_in 'amount_in_dollars', with: 200

      click_js_confirm
      click_button 'Refund this transaction'
      
      page.should have_content('This transaction was refunded')

      click_link 'another transaction'

      page.should have_content('This transaction is a refund')

      page.should have_content('-$200.00')
    end

    # payment gateway test: donate reocurring (annually) and cancel donation
    it "should cancel recurring donations" do
      donation = create(:donation, credit_card_donation_options.merge(frequency: 'annual'))
      @service.process!(donation, :ip => "75.101.145.87")

      find_transactions(donation)

      click_link 'Manage'

      page.should have_content('This annual donation was last processed at')

      click_button 'Cancel all future payments'
      dismiss_dialog

      page.should have_content('Recurring donation has been cancelled.')
    end
  end
end
