require File.dirname(__FILE__) + '/scenario_helper.rb'

describe 'recurring upgrades with Make Recurring', type: :feature, js: true do
  before :each do
    cache_db do
      seed
      
      # admin creates a campaign and blasts it out
      sign_in_as_admin email: 'admin@admin.com'
      create_campaign name: 'test campaign'
      add_page_sequence
      add_page title: 'getup asks for help' do
        add_module 'Sidebar', 'Add a donation' do
          fill_in 'Title', with: 'test title'
          fill_in 'Show progress at', with: '1'
          within '.quick-donate' do
            uncheck 'Enabled' # disable quick-donate for now
          end
          within '.make-recurring' do
            check 'Enabled'
            fill_in 'Header text', with: 'Make mine a monthly!'
            fill_in 'Body text', with: '<p>Want to donate monthly?</p>'
            fill_in 'Button text', with: 'Sign me up for {amount} per month!'
          end
        end
      end
      add_page title: 'thank you'
      send_campaign_email campaign: 'test campaign', subject: 'test campaign subject'
      click_link 'Log Out'
    end
  end

  specify 'member donates and upgrades to recurring' do
    # member receives email and visits campaign page
    open_email 'mel@member.com', with_subject: 'test campaign subject'
    visit campaign_in_email('mel@member.com', 'help my test campaign')

    click_button '$30'
    find('button', text: /Next/).click
    fill_in_email 'mel@member.com'
    fill_in 'Postcode Number', with: '2000'
    find('button', text: /Next/).click
    fill_in 'Card Number', with: '1'
    fill_in 'Name on Card', with: 'Mel Member'
    select '05', from: 'Expiry'
    select '20', from: 'donation_card_expiry_year'
    fill_in 'Security Code', with: '123'
    click_button 'DONATE $30'
    click_ajax_button 'Sign me up for $30 per month!'

    d = Donation.last
    expect(d.frequency).to eq("monthly")
    expect(d.make_recurring_at).to_not be_nil
  end
end
