require_relative "scenario_helper"

feature "recurring donor upgrade workflow", type: :feature, js: true do
  specify do
    seed

    # given recurring donor
    user = User.find_by_email "mel@member.com"
    donation = create(:recurring_donation, user: user, amount_in_cents: 100)

    # when admin emails recurring donors
    sign_in_as_admin email: "admin@admin.com"
    create_campaign name: "recurring donor upgrade"
    add_page_sequence
    add_page title: "upgrade your donation, please" do
      add_module "Sidebar", "Add a donation upgrade" do
        fill_in "Title", with: "upgrade ur donation, pls"
      end
    end
    add_page title: "thank you"
    send_campaign_email campaign: "recurring donor upgrade", subject: "upgrade ur donation" do
      check "Recurring Donor Upgrade"
    end

    # then recurring donors can upgrade from secure email link
    open_email "mel@member.com", with_subject: "upgrade ur donation"
    visit_campaign_in_email "mel@member.com", "help my test campaign"
    choose_via_id("#upgrade_amount_in_dollars_5")
    click_button "Increase by $5"

    expect(donation.reload.amount_in_cents).to eq(600)
  end
end
