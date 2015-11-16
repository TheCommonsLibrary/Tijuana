require File.dirname(__FILE__) + "/scenario_helper.rb"

describe "one click", type: :feature, js: true do
  before :each do
    cache_db do
      seed
      @postcode = FactoryGirl.create(:postcode).number
      
      # admin creates a campaign and blasts it out
      sign_in_as_admin :email => 'admin@admin.com'
      create_campaign :name => 'test campaign'
      add_page_sequence
      add_page :title => "getup asks for signature", tags: ['token-recognition'] do
        add_module 'Sidebar', 'Add a petition' do
          fill_in 'Title', :with => 'test petition'
          fill_in 'Petition statement', :with => 'test petition'
          choose 'Voice (e.g. petition)'
          fill_in 'Target number', :with => '1'
          fill_in 'Show progress at', :with => '1'
        end
      end
      add_page :title => "getup asks for money" do
        add_module 'Sidebar', 'Add a donation' do
          fill_in 'Title', :with => 'test donation'
          fill_in_code_mirror 'Lorem ipsum dolor sit amet, <strong>consectetur adipiscing elit</strong>'
          fill_in 'Show progress at', :with => '1'
        end
      end
      add_page :title => 'thank you'
      send_campaign_email :campaign => 'test campaign', :subject => 'test campaign subject'
      click_link 'Log Out'
    end
  end

  specify 'member takes action' do
    # member receives email and visits campaign page
    open_email 'mel@member.com', :with_subject => 'test campaign subject'
    visit campaign_in_email('mel@member.com', 'help my test campaign')

    # member signs petition
    fill_in 'user_email', with: 'action_taker@user.com'
    user_lookup_complete
    fill_in 'First Name*', with: 'Darren'
    fill_in 'Last Name*', with: 'Loasby'
    fill_in 'Postcode Number*', with: @postcode
    click_button 'Sign the petition!'

    # make a donation on the next daisy chained page - should be one click
    click_button '$12'
    find("button", :text => /Next/).click
    sleep(0.5)
    find("button", :text => /Next/).click
    fill_in 'Card Number', :with => '1'
    fill_in 'Name on Card', :with => 'Mel Member'
    select '05', :from => 'Expiry'
    select '20', :from => 'donation_card_expiry_year'
    fill_in 'Security Code', :with => '123'
    responsive_screenshot 'step 3'
    click_button 'DONATE $12'
    click_ajax_button 'Yes, remember me'

    # repeat petition - should now be one click
    visit campaign_in_email('mel@member.com', 'help my test campaign')
    click_button 'Sign the petition!'

    # repeat donation with quick donate
    click_button '$12'
    click_button 'DONATE $12'
    expect(page).to have_content('thank you')

    # repeat petition - but opt out
    visit campaign_in_email('mel@member.com', 'help my test campaign')
    click_link 'Not you?'
    fill_in 'user_email', with: 'action_taker@user.com'
    user_lookup_complete
    click_button 'Sign the petition!'
  end
end
