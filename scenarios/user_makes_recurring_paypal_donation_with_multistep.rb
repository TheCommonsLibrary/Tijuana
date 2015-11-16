require File.dirname(__FILE__) + "/scenario_helper.rb"

describe "recurring paypal donation with multistep", type: :feature, js: true do
  before :each do
    cache_db do
      seed
      
      sign_in_as_admin :email => 'admin@admin.com'
      create_campaign :name => 'test campaign'
      add_page_sequence
      add_page :title => "getup asks for help" do
        add_module 'Sidebar', 'Add a donation' do
          fill_in 'Title', :with => 'test title'
          fill_in_code_mirror 'Lorem ipsum dolor sit amet, <strong>consectetur adipiscing elit</strong>, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.'
          fill_in 'Show progress at', :with => '1'
          select 'Hidden', from: 'Donate Once'
          select 'Default', from: 'Donate Weekly'
          check 'Use fixed amounts'
        end
      end
      add_page :title => 'thank you'
      send_campaign_email :campaign => 'test campaign', :subject => 'test campaign subject'
      click_link 'Log Out'
    end
  end

  specify 'member donates' do
    # member receives email and visits campaign page
    open_email 'mel@member.com', :with_subject => 'test campaign subject'
    visit_campaign_in_email 'mel@member.com', 'help my test campaign'
    campaign_path = current_path
    
    # member donates via paypal
    visit campaign_path
    click_button '$30'
    find("button", :text => /Next/).click
    fill_in_email 'mel@member.com'
    fill_in 'Postcode Number', :with => '2000'
    find("button", :text => /Next/).click
    find("#multistep-paypal-form").has_css?("[target='_top']")
    page.execute_script("$('#multistep-paypal-form').attr('action', 'http://localhost:8282/fake_paypal');")
    find('a', :text => /Donate with PayPal/).click
    page.should have_content('a3: 30')
    page.should have_content("t3: 'W'")
  end
end
