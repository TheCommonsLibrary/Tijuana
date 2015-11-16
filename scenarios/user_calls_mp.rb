require File.dirname(__FILE__) + "/scenario_helper.rb"

describe 'User calls MP', type: :feature, js: true do
  before(:each) do
    Timecop.travel "12 Feb 2015"
    
    cache_db do
      seed
      ElectoralSeeder.seed_electoral_data
      
      # admin creates a campaign and blasts it out
      sign_in_as_admin :email => 'admin@admin.com'
      create_campaign :name => 'test campaign'
      add_page_sequence
      add_page :title => 'ask page' do
        add_module 'Sidebar', 'Add a call to MP' do
          fill_in 'Title', :with => 'test title'
          check 'Australian Labor Party'
          select 'MPs with fallback to Senators if MP is not targeted', :from => 'Target'
          check 'Schedule calls'
          fill_in 'Schedule start', :with => '12-02-2015'
          fill_in 'Schedule end', :with => '12-02-2015'
          select 'Every 1/2 hour', :from => 'Schedule frequency'
        end
      end
      add_page :title => 'thank you'
      send_campaign_email :campaign => 'test campaign', :subject => 'test campaign subject'
      click_link 'Log Out'
    end
  end

  it "should record user calling their MP" do
    open_email 'mel@member.com', :with_subject => 'test campaign subject'
    visit_campaign_in_email 'mel@member.com', 'help my test campaign'
    campaign_path = current_path
    
    # Go through twice with different members to see time slot is taken
    ['mel@member.com', 'matt@member.com'].each do |member_email|
      # member enters details
      visit campaign_path
      click_link 'Not you?' if member_email == 'matt@member.com' # page remembers mel after taking action
      fill_in 'user_email', with: member_email
      user_lookup_complete
      fill_in 'Postcode Number', :with => '2010'
    
      # member enters postcode and selects mp that is not target
      fill_in 'mp_postcode', with: '2010'
      choose "Bernard Cooper MP (LP) - Minas Anor"
    
      if member_email == 'mel@member.com'
        # member schedules call
        select 'Today 12 Feb at 12:30pm', :from => 'When will you call?'
        page.should have_content "Please call your Senator Lucius Washington"
        page.should have_content '(02) 6277 7630'
        
        click_button 'I CALLED!'
        page.should have_content 'thank you'
      else
        within page.find_field('When will you call?') do
          page.find('option', :text => 'Today 12 Feb at 12:30pm').should be_disabled
        end
      end
    end
    
    # member chooses different mp and sees no slots are taken yet
    choose 'Danny Butterman MP (ALP) - Oatbarton'
    within page.find_field('When will you call?') do
      page.should_not have_css 'option[disabled]'
    end
    
    # admin goes back in and changes to arbitrary target
    sign_in_as_admin :email => 'admin@admin.com'
    click_links 'Admin', 'ask page'
    check 'Arbitrary target'
    click_button 'Save page'
    click_link 'Log Out'
    
    # member schedules call with arbitrary target
    visit campaign_path
    fill_in 'user_email', with: 'matt@member.com'
    user_lookup_complete
    fill_in 'Postcode Number', :with => '2010'
    select 'Today 12 Feb at 12:30pm', :from => 'When will you call?'
    click_button 'I CALLED!'
    page.should have_content 'thank you'
    
    # admin goes back in and changes to call schedule
    sign_in_as_admin :email => 'admin@admin.com'
    click_links 'Admin', 'ask page'
    fill_in 'Schedule start', :with => '12-02-2015'
    fill_in 'Schedule end', :with => '13-02-2015'
    click_button 'Save page'
    click_link 'Log Out'
    
    # member goes back in and sees new time slots
    visit campaign_path
    page.should have_css 'option', :text => 'Fri 13 Feb at 09:00am'
  end
end
