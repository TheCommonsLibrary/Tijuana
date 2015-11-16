require_relative "scenario_helper"
include ApplicationHelper

feature 'donor is identified as shown personalised amounts', js: true do
  
  context 'donor makes first donation and then returns for second donation from the same device' do
    specify do 
      seed

      # Create a donation ask and email as admin
      sign_in_as_admin email: "admin@admin.com"
      create_campaign name: "one off ask"
      add_page_sequence
      add_page title: "make a one off donation" do
        add_module "Sidebar", "Add a donation" do
          fill_in "Title", with: "donate please"
          fill_in 'Show progress at', with: '1000'
        end
      end
      ask_page_url = friendly_path(Page.last)
      add_page title: "thank you"
      send_campaign_email campaign: 'one off ask', subject: "make ur donation"
      click_link 'Log Out'
    
      # Visit the page as member. First visit should show only default amounts
      visit ask_page_url
      expect(find_button('$12'))
    
      # Make $30 donation
      click_button '$30'
      find("button", :text => /Next/).click
      fill_in_email 'matt@member.com'
      fill_in 'Postcode Number', :with => '2000'
      find("button", :text => /Next/).click
      fill_in 'Card Number', :with => '1'
      fill_in 'Name on Card', :with => 'Matt Member'
      select '05', :from => 'Expiry'
      select '20', :from => 'donation_card_expiry_year'
      fill_in 'Security Code', :with => '123'
      click_button 'DONATE $30'
      
      choose_experiment_alternative(:personalised_amounts_v4, :relative)
      visit ask_page_url
      expect(find_button('$42'))
      
      # Visit the page via email link. The member specified in the link should override the cookie
      open_email "mel@member.com", with_subject: "make ur donation"
      visit_campaign_in_email "mel@member.com", "help my test campaign"
      expect(find_button('$12'))
    end
  end
end
