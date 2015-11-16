require File.dirname(__FILE__) + "/scenario_helper.rb"

describe "Member takes action", type: :feature, js: true do
  context "from another members share" do
    it "should create a shared connection" do
      email = create(:email)
      originator = create(:user, email: 'originator@user.com')
      token = EmailTrackingToken.encode(originator.id, email.id)

      campaign = create(:campaign, name: 'campaign_name')
      page_sequence = create(:page_sequence, campaign: campaign, name: 'page_sequence')
      page1 = create(:page, page_sequence: page_sequence, name: 'page', position: 1)
      page2 = create(:page, page_sequence: page_sequence, position: 2, name: "Thanks for taking action")
      petition_module = create(:petition_module)
      addthis_module = create(:tell_a_friend_ask_module)
      create(:content_module_link, page: page1, content_module: petition_module, layout_container: :sidebar)
      create(:content_module_link, page: page2, content_module: addthis_module, layout_container: :sidebar)

      page.driver.add_headers("Referer" => "http://www.facebook.com")

      visit "/campaigns/campaign_name/page_sequence/page?t=#{token}"

      fill_in 'user_email', with: 'action_taker@user.com'

      user_lookup_complete

      click_button 'Sign the petition!'

      page.should have_content(page2.name)

      action_taker = User.find_by_email('action_taker@user.com')
      uae = UserActivityEvent.find_last_by_user_id(action_taker.id)
      connection = SharedConnections.find_last_by_originator_id(originator.id)

      connection.action_taker.should == action_taker
      connection.user_activity_event.should == uae
      connection.http_referrer.should == 'http://www.facebook.com'
    end
  end

  context "with no referral" do
    context 'with no token' do
      it "should NOT create a shared connection" do
        campaign = create(:campaign, name: 'campaign_name')
        page_sequence = create(:page_sequence, campaign: campaign, name: 'page_sequence')
        page1 = create(:page, page_sequence: page_sequence, name: 'page', position: 1)
        page2 = create(:page, page_sequence: page_sequence, position: 2, name: "Thanks for taking action")
        petition_module = create(:petition_module)
        create(:content_module_link, page: page1, content_module: petition_module, layout_container: :sidebar)

        visit "/campaigns/campaign_name/page_sequence/page"

        fill_in 'user_email', with: 'action_taker@user.com'

        user_lookup_complete

        click_button 'Sign the petition!'

        page.should have_content(page2.name)

        action_taker = User.find_by_email('action_taker@user.com')
        uae = UserActivityEvent.find_last_by_user_id(action_taker.id)
        connection = SharedConnections.find_last_by_action_taker_id(action_taker.id)

        uae.blank?.should_not be true
        connection.blank?.should be true
      end
    end

    context 'with their own token' do
      it "should NOT create a shared connection" do
        email = create(:email)
        originator = create(:user, email: 'originator@user.com')
        token = EmailTrackingToken.encode(originator.id, email.id)

        campaign = create(:campaign, name: 'campaign_name')
        page_sequence = create(:page_sequence, campaign: campaign, name: 'page_sequence')
        page1 = create(:page, page_sequence: page_sequence, name: 'page', position: 1)
        page2 = create(:page, page_sequence: page_sequence, position: 2, name: "Thanks for taking action")
        petition_module = create(:petition_module)
        addthis_module =create(:tell_a_friend_ask_module)
        create(:content_module_link, page: page1, content_module: petition_module, layout_container: :sidebar)
        create(:content_module_link, page: page2, content_module: addthis_module, layout_container: :sidebar)

        visit "/campaigns/campaign_name/page_sequence/page?t=#{token}"

        fill_in 'user_email', with: 'originator@user.com'

        user_lookup_complete

        click_button 'Sign the petition!'

        page.should have_content(page2.name)

        uae = UserActivityEvent.find_last_by_user_id(originator.id)
        connection = SharedConnections.find_last_by_action_taker_id(originator.id)

        uae.blank?.should_not be true
        connection.blank?.should be true
      end
    end
  end
end
