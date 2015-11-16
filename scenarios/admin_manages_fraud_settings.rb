require File.dirname(__FILE__) + "/scenario_helper.rb"

describe "Admin manages fraud settings", type: :feature do
  before(:each) do
    User.create(email: 'mygetup@getup.org.au', password: 'password', is_admin: true)
    sign_in_as_admin
  end

  it "should update blocked IPs and toggle fraud guard" do
    visit admin_payments_path
    fill_in 'ip_addresses', with: '1.1.1.1,2.2.2.2 3.3.3.3'
    within(:xpath, "//div[h3/text()='Blocked IPs']") { click_button 'submit' }
    page.should have_content('1.1.1.1')
    page.should have_content('2.2.2.2')
    page.should have_content('3.3.3.3')
    choose('fraud_guard_enabled')
    find('div#fraudguard input[type=submit]').click
    page.should have_content('Enabled')
    find('#fraud_guard_enabled').value.should_not be_blank
  end
end
