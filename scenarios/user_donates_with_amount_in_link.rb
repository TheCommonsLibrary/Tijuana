require File.dirname(__FILE__) + "/scenario_helper.rb"

describe "multistep donate with amount specified in email link", type: :feature, js: true do
  before :each do
    cache_db do
      seed
      
      # admin creates a campaign and blasts it out
      sign_in_as_admin :email => 'admin@admin.com'
      create_campaign :name => 'test campaign'
      add_page_sequence
      add_page :title => "getup asks for help" do
        add_module 'Sidebar', 'Add a donation' do
          fill_in 'Title', :with => 'test title'
          fill_in_code_mirror 'Lorem ipsum dolor sit amet, <strong>consectetur adipiscing elit</strong>, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.'
          fill_in 'Show progress at', :with => '1'
        end
      end
      add_page :title => 'thank you'
      send_campaign_email :campaign => 'test campaign', :subject => 'test campaign subject', params: {a: 30}
      click_link 'Log Out'
    end
  end

  specify 'member donates and preselects donation amount' do
    # member receives email and visits campaign page
    open_email 'mel@member.com', :with_subject => 'test campaign subject'
    visit_with_vanity_alternative campaign_in_email('mel@member.com', 'help my test campaign'), :personalised_amounts_v4, :static
    
    campaign_path = current_path
    
    # member donates on desktop
    find("button", :text => /Next/).click
    fill_in_email 'mel@member.com'
    fill_in 'Postcode Number', :with => '2000'
    responsive_screenshot 'step 2'
    find("button", :text => /Next/).click
    fill_in 'Card Number', :with => '1'
    fill_in 'Name on Card', :with => 'Mel Member'
    select '05', :from => 'Expiry'
    select '20', :from => 'donation_card_expiry_year'
    fill_in 'Security Code', :with => '123'
    responsive_screenshot 'step 3'
    click_button 'DONATE $30'
    click_ajax_button 'Yes, remember me'
    
    # member quick donates on desktop
    visit campaign_path
    click_button '$70'
    responsive_screenshot 'quick donate'
    click_button 'DONATE $70'
    
    # member quick donates on mobile
    resize_window *mobile_portrait_size
    visit campaign_path
    click_button '$70'
    click_button 'DONATE $70'
    
    # member full donates on mobile
    visit campaign_path
    click_link 'Not you or different card?'
    fill_in_email 'mel@member.com'
    fill_in 'Postcode Number', :with => '2000'
    fill_in 'Card Number', :with => '1'
    fill_in 'Name on Card', :with => 'Mel Member'
    select '05', :from => 'Expiry'
    select '20', :from => 'donation_card_expiry_year'
    fill_in 'Security Code', :with => '123'
    click_button 'DONATE $70'
    
    # member donates via paypal
    visit campaign_path
    click_button '$140'
    page.execute_script("$('#multistep-paypal-form').attr('action', 'http://localhost:8282/fake_paypal');")
    find('a', :text => /Donate with PayPal/).click
    page.should have_content 'Fake PayPal is ready to donate $140 to test campaign'
    
    # admin checks that donation was made
    resize_window *large_desktop_size
    sign_in_as_admin :email => 'admin@admin.com'
    click_links 'Admin', 'Transactions'
    within 'table.transactions' do
      within('tr:nth-child(2)') { page.should have_content '$70' }
      within('tr:nth-child(3)') { page.should have_content '$70' }
      within('tr:nth-child(4)') { page.should have_content '$70' }
      within('tr:nth-child(5)') { page.should have_content '$30' }
    end
  end
end
