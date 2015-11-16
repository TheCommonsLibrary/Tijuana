require_relative "scenario_helper"

feature 'recurring donation with fixed amounts workflow', js: true do
  context "with eligible_for_personalised_donation_tests module" do
    specify do
      seed
      sign_in_as_admin email: "admin@admin.com"
      create_campaign name: "recurring donor ask"
      add_page_sequence
      add_page title: "make a recurring donation" do
        add_module "Sidebar", "Add a donation" do
          fill_in "Title", with: "upgrade ur donation, pls"
          select 'Hidden', from: 'Donate Once'
          select 'Default', from: 'Donate Weekly'
          check 'Use fixed amounts'
          fill_in "Suggested amounts", with: '400, 50*, 35*, 10*, 5, 3'
          fill_in "Default amount", with: '35'
          fill_in 'Show progress at', with: '1000'
        end
      end
      add_page title: "thank you"
      send_campaign_email campaign: "recurring donor ask", subject: "make ur donation"
      open_email_and_donate_with(35)
      user = User.find_by_email "mel@member.com"
      expect(user.donations.recurring.last.amount_in_cents).to eq(3500)
    end
  end

  context 'with an existing module' do
    specify do
      seed
      sign_in_as_admin email: "admin@admin.com"
      create_campaign name: "recurring donor ask (existing)"
      add_page_sequence
      page_name = 'make a recurring donation (existing)' 
      add_page title: page_name
      add_page title: 'thank you'
      page = Page.find_by_name(page_name)
      existing_module = create(:donation_module, frequency_options: { 'one_off' => 'hidden', 'weekly' => 'default', 'monthly' => 'hidden', 'annual' => 'hidden' }, eligible_for_personalised_donation_tests: false)
      page.content_module_links.create!(content_module: existing_module, layout_container: :sidebar)
      visit "/admin/pages/#{page.id}/edit"
      fill_in "Suggested amounts", with: '400, 50*, 45*, 10*, 5, 3'
      fill_in "Default amount", with: '45'
      fill_in 'Show progress at', with: '1000'
      click_button "Save page"
      send_campaign_email campaign: 'recurring donor ask (existing)', subject: "make ur donation"
      open_email "mel@member.com", with_subject: "make ur donation"
      visit_campaign_in_email "mel@member.com", "help my test campaign"
      open_email_and_donate_with(45)

      user = User.find_by_email "mel@member.com"
      expect(user.donations.recurring.last.amount_in_cents).to eq(4500)
    end
  end

  def open_email_and_donate_with(amount)
    open_email "mel@member.com", with_subject: "make ur donation"
    visit_campaign_in_email "mel@member.com", "help my test campaign"
    click_button 'Next ›'
    fill_in 'Email Address', with: 'mel@member.com'
    fill_in 'Postcode Number', :with => '2000'
    click_button 'Next ›'
    fill_in 'Card Number', :with => '1'
    fill_in 'Name on Card', :with => 'Mel Member'
    select '05', :from => 'Expiry'
    select '20', :from => 'donation_card_expiry_year'
    fill_in 'Security Code', :with => '123'
    click_button "DONATE $#{amount}"
  end
end
