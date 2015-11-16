require File.dirname(__FILE__) + "/scenario_helper.rb"
describe "user updates card", type: :feature do
  let!(:weekly_donor) { FactoryGirl.create(:user, email: "weekly_donor@user.com") }
  let!(:weekly_donation) { FactoryGirl.create(:donation,
                                         :user => weekly_donor,
                                         :card_number => PaymentGateways::CARD_FAILURE,
                                         :frequency => "weekly",
                                         :card_expiry_month => "1",
                                         :card_expiry_year => "20")}

  after :each do
    Timecop.return
  end

  context "can be updated" do
    it "donation is flagged" do
      weekly_donation.flagged_since = Time.local(2015, 04, 10)
      weekly_donation.save!

      visit_update_page_and_assert_update(weekly_donation)
    end

    it "card is going to expired in next 10 days" do
      Timecop.travel(Time.local(2019, 12, 22))
      visit_update_page_and_assert_update(weekly_donation)
    end

    it "failure email has been sent to donor and no successful transaction since that time" do
      SentTriggerEmail.create(user_id: weekly_donation.user.id,
                              key: :donation_failing_email,
                              triggered_by: weekly_donation,
                              sent_date: Time.local(2019, 04, 8))
      visit_update_page_and_assert_update(weekly_donation)
    end
  end

  context "can NOT update card" do
    before { Timecop.travel(Time.local(2019, 11, 22)) }

    it "donation is not flagged and card is not expired in next 10 days and no failure email has been sent" do
      visit dashboard_update_card_url(weekly_donation)

      page.should have_content("We couldn't find that page! Maybe you typed the address wrong, so check what you typed. But it could also be our problem, so if that doesn't work please contact us.")
    end

    it "donation is not flagged and card is not expired in next 10 days and failure email has been sent and has successfull transaction since that time" do
      SentTriggerEmail.create(user_id: weekly_donation.user.id,
                              key: :donation_failing_email,
                              triggered_by: weekly_donation,
                              sent_date: Time.local(2019, 04, 8))
      FactoryGirl.create(:transaction, donation: weekly_donation, created_at: Time.local(2019, 04, 9))
      visit dashboard_update_card_url(weekly_donation)

      page.should have_content("We couldn't find that page! Maybe you typed the address wrong, so check what you typed. But it could also be our problem, so if that doesn't work please contact us.")
    end
  end

  private

  def visit_update_page_and_assert_update(donation)
    visit dashboard_update_card_url(donation)
    assert_can_be_updated(page)

    update_card_infos
    page.should have_content("Ok")
  end

  def assert_can_be_updated(page)
    page.should have_content("UPDATE YOUR DONATION DETAILS")
  end

  def update_card_infos
    fill_in "donation_#{weekly_donation.id}_card_number", with: PaymentGateways::CARD_SUCCESS
    fill_in "donation_#{weekly_donation.id}_name_on_card", with: "Username"
    fill_in "donation_card_expiry_month", with: 12
    fill_in "donation_card_expiry_year", with: 2020
    fill_in "donation_card_cvv", with: 123

    click_button "Save"
  end
end
