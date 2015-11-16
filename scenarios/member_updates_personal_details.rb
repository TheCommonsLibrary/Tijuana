require File.dirname(__FILE__) + "/scenario_helper.rb"

describe "Member updates personal details", type: :feature, js: true do

  EXPECTED_VALUES = {first_name: 'Lisa', last_name: 'Someone', email: 'lisa@thoughtworks.com',
                     home_phone: '98877654', mobile_number: '0420984257',
                     street_address: 'Rappy Street', suburb: 'Surry Hills'}

  let(:user) { create(:user, email: "bart@simpson.com", first_name: "Bart", last_name: "Simpson", password: "password") }

  context "Personal Details" do
    before(:each) do
      user
      sign_in :email => 'bart@simpson.com'
    end

    it "page should render the correct open graph data" do
      page.should have_meta "og:title", "GetUp! Action for Australia"
      page.should have_meta "og:description", "An independent movement to build a progressive Australia and bring participation back into our democracy."
      page.should have_meta "og:image", %r{http://#{URI(current_url).host}:#{URI(current_url).port}/assets/public/getup_logo(.*)\.png}
      page.should have_meta "og:type", "non_profit"
      page.should have_meta "og:site_name", "GetUp! Action for Australia"
    end

    it "should load and update valid personal details" do
      page.should have_content "PERSONAL DETAILS"
      has_user_details(first_name: 'Bart', last_name: 'Simpson', email: 'bart@simpson.com')
      fill_in_personal_details(EXPECTED_VALUES)
      select "AUSTRALIA", from: "Country"

      click_button "Save"
      page.should have_content "Your personal details have been updated!"

      visit_dashboard
      has_user_details(EXPECTED_VALUES)
      has_field_value "Country", "AU"
    end

    it "should show errors with invalid personal details" do
      page.should have_content "PERSONAL DETAILS"
      has_user_details(first_name: 'Bart', last_name: 'Simpson', email: 'bart@simpson.com')
      fill_in_personal_details(email: "something_wrong")

      click_button "Save"
      page.should_not have_content "Your personal details have been updated!"
      page.should have_content "email is invalid."

      visit_dashboard
      has_user_details(email: 'bart@simpson.com')
    end
  end

  context "Donation Details" do
    context "Member has no donation" do
      it "should show a message" do
        user
        sign_in :email => 'bart@simpson.com'
        click_link "DONATIONS"
        page.should have_content "You don't have any recurring donations."
      end
    end

    context "Member has donations" do
      let(:donation) { create(:donation, user: user, frequency: "monthly") }
      let(:transaction) { create(:transaction, donation: donation) }
      before(:each) do
        transaction
        sign_in :email => 'bart@simpson.com'
      end

      it "should update credit card details" do
        click_link "DONATIONS"
        page.should have_content 'Core Member'
        fill_in "donation_#{donation.id}_amount_in_dollars", with: '34.32'
        fill_in "donation_#{donation.id}_card_number", with: PaymentGateways::CARD_SUCCESS
        fill_in "donation_#{donation.id}_card_cvv", with: '432'
        click_button 'Save'
        page.should have_content 'Your payment information has been updated!'
      end

      it "should show user's donation history" do
        click_link "DONATION HISTORY"
        page.should have_content transaction.created_at.strftime("%d/%m/%Y")
        page.should have_content 'Credit card'
        page.should have_content 'Core Member'
        page.should have_content "$#{transaction.amount_in_cents.to_f/100}"
      end
    end
  end

  private

  def has_user_details(details)
    details.each do |field, value|
      has_field_value field.to_s.titleize, value
    end
  end

  def has_field_value(field, value)
    find_field(field).value.should == value
  end

  def fill_in_personal_details(details)
    details.each do |field, value|
      fill_in field.to_s.titleize, with: value
    end
  end

  def visit_dashboard
    visit "/dashboard"
  end

  def create_recurring_donation email
    @recurring_donation = create(:recurring_donation, :user => User.find_by_email(email))
  end

  def fill_in_element_with_helper(field_value, field_name)
    element = "donation-#{@recurring_donation.id}-#{field_name}-helper"
    previewElement = "##{element} ~ div:first"
    page.execute_script "$('#{previewElement}').trigger('click');"
    fill_in(element, :with => field_value)
    page.execute_script "$('##{element}').trigger('blur');"
  end

  def change_my_card_expiry_to month, year
    month_select = "donation_#{@recurring_donation.id}_card_expiry_month"
    select(month, :from => month_select)

    year_select = "donation_#{@recurring_donation.id}_card_expiry_year"
    select(year, :from => year_select)
  end

  def change_card_type(card_type)
    card_type_select = "donation_#{@recurring_donation.id}_card_type"
    select(card_type, :from => card_type_select)
  end

  def click_dashboard_button name
    click_button(name);
    wait_until do
      page.evaluate_script('$.active') == 0
    end
  end

end
