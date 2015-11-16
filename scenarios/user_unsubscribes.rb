require File.dirname(__FILE__) + "/scenario_helper.rb"

describe "User unsubscribes", type: :feature do
  before(:each) do
    @user = User.create!(email: 'iam@anewuser.com')
  end

  context "getup" do
    it "should unsubscribe user" do
      visit '/unsubscribe'
      fill_in 'user_email', with: 'iam@anewuser.com'
      choose 'No longer interested'
      click_button 'Unsubscribe'
      
      page.should have_content 'successfully cancelled'
    end
  end

  context 'community run' do
    it "should unsubscribe user" do
      visit '/unsubscribe?cr=true'
      fill_in 'user_email', with: 'iam@anewuser.com'
      click_button 'Unsubscribe'
      
      page.should have_content 'successfully cancelled'
    end
  end
end
