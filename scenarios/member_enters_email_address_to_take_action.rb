require File.dirname(__FILE__) + "/scenario_helper.rb"
include ApplicationHelper

describe "Member enters email address to take action", type: :feature, js: true do

  before(:each) do
    set_up_pages
    visit_petition
  end

  describe "New member" do
    it "will be automatically prompted for further details after they finish typing their email" do
      User.find_by_email('newperson@hotmail.com').try(:destroy)
      fill_in 'user_email', :with => 'newperson@hotmail.com'
      user_lookup_complete
      page.should have_content "visiting for the first time"
      find_field('user_first_name').visible?.should be true
    end
  end

  describe "Existing member" do

    before(:each) do
      @user=create(:user, :email=>'existing@hotmail.com', :first_name=>'first', :last_name=>'last')
    end

    it "will not be prompted for further details if they are on file" do
      fill_in 'user_email', :with => @user.email
      user_lookup_complete
      page.should have_content "Thanks for entering your email."
      page.should have_css("#user_first_name", :visible => false)
    end

    it "can enter email with extra whitespace" do
      fill_in 'user_email', :with => " #{@user.email}   "
      page.should have_content "Thanks for entering your email."
    end

    it "with details on file signs petition after only entering their email" do
      fill_in 'user_email', :with => @user.email
      user_lookup_complete
      click_button "Sign the petition!"
      page.should have_content "What's Happening"
    end
  end

  def set_up_pages
    @page = create(:page_with_parent, :required_user_details => {:first_name => :required, :last_name => :required,
      :postcode_number=>:hidden, :mobile_number=>:hidden, :home_number=>:hidden, :street_address=>:hidden,
      :suburb=>:hidden, :country=>:hidden})

    petition = PetitionModule.create!(
      :title => "Sign, please",
      :content => 'We the undersigned...',
      :petition_statement => "This is the petition statement",
      :signatures_target => 0,
      :thermometer_threshold => 0
    )
    ContentModuleLink.create!(:page => @page, :content_module => petition, :position => 1, :layout_container => :sidebar)

    MemberCountCalculator.init
    Homepage.create!(
        :banner_text => "OUR HOME PAGE",
        :campaign_image => "/images/homepage-campaign1-placeholder.jpg",
        :campaign_url => "/donate",
        :campaign_alt_text => "Donate to GetUp!",
        :campaign2_image => "/images/homepage-campaign2-placeholder.jpg",
        :campaign2_url => "/donate",
        :campaign2_alt_text => "Donate to GetUp!",
        :campaign3_image => "/images/homepage-campaign3-placeholder.jpg",
        :campaign3_url => "/donate",
        :campaign3_alt_text => "Donate to GetUp!"
      )
  end

  def visit_petition
    visit_with_vanity_alternative(friendly_path(@page), :sign_with_fb, :control)
  end

end
