require_relative "scenario_helper"

describe "large donations require a street address", type: :feature, js: true do
  before :each do
    cache_db do
      seed
      ElectoralSeeder.seed_electoral_data # required for postcodes

      # admin creates a campaign and blasts it out
      sign_in_as_admin email: "admin@admin.com"
      create_campaign name: "test campaign"
      add_page_sequence
      add_page title: "getup asks for help" do
        add_module "Sidebar", "Add a donation" do
          fill_in "Title", with: "test title"
          check 'Use fixed amounts'
          fill_in "Suggested amounts", with: '250*, 50*, 35*, 12*, 5, 3'
          fill_in "Default amount", with: '35'
          fill_in "Show progress at", with: "1"
        end
      end
      add_page title: "thank you"
      send_campaign_email campaign: "test campaign", subject: "test campaign subject"
      click_link "Log Out"
    end
  end

  specify "existing member donates a large amount" do
    open_email "mel@member.com", with_subject: "test campaign subject"
    visit_campaign_in_email "mel@member.com", "help my test campaign"

    # enter a large amount in the "Other" field
    click_button "$250"
    find("button", text: /Next/).click
    fill_in_email "mel@member.com"
    user_lookup_complete

    # hitting the next button should trigger address validation
    find("button", text: /Next/).click
    find('.alert-block', text: /street address/i)
    find('.alert-block', text: /suburb/i)
    find('.alert-block', text: /postcode number/i)

    # should be able to fill in the address details and submit the form
    fill_in 'Street Address', with: '338 Pitt St'
    fill_in 'Postcode Number', with: '2000'
    fill_in 'Suburb', with: 'Sydney'
    find("button", text: /Next/).click

    fill_in 'Card Number', :with => '1'
    fill_in 'Name on Card', :with => 'Mel Member'
    select '05', :from => 'Expiry'
    select '20', :from => 'donation_card_expiry_year'
    fill_in 'Security Code', :with => '123'
    click_button 'DONATE $250'

    user = User.find_by_email('mel@member.com')
    user.street_address.should == '338 Pitt St'
    user.donations.last.amount_in_cents.should == 25000
  end
end
