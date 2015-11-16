require File.dirname(__FILE__) + "/scenario_helper.rb"

#this should be a spec but render_views requires a lot of setup
describe "multistep donate", type: :feature, js: true do
  before :each do
    cache_db do
      seed
      
      # admin creates a campaign and blasts it out
      sign_in_as_admin :email => 'admin@admin.com'
      create_campaign :name => 'test campaign'
      add_page_sequence
      add_page :title => 'ask page' do
        add_module 'Sidebar', 'Add a donation' do
          fill_in 'Title', :with => 'test title'
          fill_in_code_mirror 'Lorem ipsum'
          fill_in 'Show progress at', :with => '1'
        end
      end
      add_page :title => 'thank you'
      send_campaign_email :campaign => 'test campaign', :subject => 'test campaign subject'
      click_link 'Log Out'
    end
  end

  specify 'member visits page with analytics' do
    open_email 'mel@member.com', :with_subject => 'test campaign subject'
    visit_campaign_in_email 'mel@member.com', 'help my test campaign'

    page.html.should include("ga('set', 'dimension2', 'ask page')")
  end
end
