require File.dirname(__FILE__) + "/scenario_helper.rb"

describe "User emails target", type: :feature do

  before(:each) do
    @user = create(:user, email: 'user@user.com')
    Delayed::Job.delete_all # delete welcome email job
    ActionMailer::Base.deliveries = []
  end

  context "with talking points" do
    before :each do
      set_up_pages
      @email_targets.talking_points << TalkingPoint.new(short_description: 'First Point', long_description: "First long description")
      @email_targets.talking_points << TalkingPoint.new(short_description: 'Second Point', long_description: "Second long description")
    end

    it "shows talking points" do
      visit page_path(@campaign.id, @page_sequence.id, @page.id)
      click_link("Not sure what to say?")
      talking_points = page.all(:css, '.talking-points-short-description').map(&:text).map(&:strip)
      talking_points.should include 'First Point'
      talking_points.should include 'Second Point'
    end
  end

  context "without talking points" do

    before(:each) do
      set_up_pages
    end

    it "should display email subject and body as placeholder" do
      @email_targets.email_prompt_as = EmailModule::EMAIL_PLACEHOLDER
      @email_targets.save!

      visit page_path(@campaign.id, @page_sequence.id, @page.id)
      page.should_not have_content "Not sure what to say?"

      page.should have_xpath("//textarea[@placeholder='This is the default body' and @id='user_email_body']")
      page.should have_xpath("//input[@placeholder='This is the default subject...' and @id='user_email_subject']")
      find(:xpath, "//textarea[@placeholder='This is the default body' and @id='user_email_body']").value.should be_blank
      find(:xpath, "//input[@placeholder='This is the default subject...' and @id='user_email_subject']").value.should be_blank
    end

    it "should send an email with default content to the target and CC the user" do
      visit page_path(@campaign.id, @page_sequence.id, @page.id)
      fill_in 'user_email', with: @user.email
      fill_in 'user_first_name', with: 'Bill'
      fill_in 'user_last_name', with: 'Bill'

      check('user_email_cc_me')
      page.find('.btn-primary').click

      page.should have_content 'Thanks for taking action'

      success, failures = Delayed::Worker.new.work_off
      ActionMailer::Base.deliveries.size.should == 2
      first = ActionMailer::Base.deliveries.first
      last = ActionMailer::Base.deliveries.last
      if first.to.first == @user.email
        last.to.first.should == @target_email
      else
        first.to.first.should == @target_email
        last.to.first.should == @user.email
      end
      first.subject.should == @email_subject
      last.subject.should == @email_subject
    end

    it "should send an email to target with user supplied content and no cc to self" do
      visit page_path(@campaign.id, @page_sequence.id, @page.id)
      fill_in 'user_email', with: @user.email
      fill_in 'user_first_name', with: 'Bill'
      fill_in 'user_last_name', with: 'Bill'
      fill_in 'user_email_subject', with: 'new subject line'
      fill_in 'user_email_body', with: 'new email body here'

      page.find('.btn-primary').click
      page.should have_content 'Thanks for taking action'

      success, failures = Delayed::Worker.new.work_off
      ActionMailer::Base.deliveries.size.should == 1
      ActionMailer::Base.deliveries.first.to.first.should == @target_email
      ActionMailer::Base.deliveries.first.subject.should == 'new subject line'
      ActionMailer::Base.deliveries.first.encoded.should include('new email body here')
    end

    it "should not send email to target" do
      @email_targets.send_to_target = '0'
      @email_targets.save!

      visit page_path(@campaign.id, @page_sequence.id, @page.id)
      fill_in 'user_email', with: @user.email
      fill_in 'user_first_name', with: 'Bill'
      fill_in 'user_last_name', with: 'Bill'
      fill_in 'user_email_subject', with: 'not for target'
      fill_in 'user_email_body', with: "target won't see this email"

      page.find('.btn-primary').click
      page.should have_content 'Thanks for taking action'

      Delayed::Worker.new.work_off
      ActionMailer::Base.deliveries.size.should == 0
    end

  end

  def set_up_pages
    @campaign = create(:campaign)
    @page_sequence = create(:page_sequence, campaign: @campaign, theme: create(:theme))
    @page = create(:page, page_sequence: @page_sequence, position: 1)
    @page2 = create(:page, page_sequence: @page_sequence, position: 2, name: "Thanks for taking action")
    @postcode = create(:postcode)
    @target_email = 'target@target.com'
    @email_subject = 'This is the default subject...'

    @email_targets = EmailTargetsModule.create!(
        :title => 'Email target',
        :content => 'This is the content',
        :default_subject => @email_subject,
        :default_body => 'This is the default body',
        :target_emails => @target_email
    )
    content = "<p>This is test content only: 123</p>"
    ContentModuleLink.create!(page: @page, content_module: StandfirstModule.create(content: content), position: 1, layout_container: :main_content)
    ContentModuleLink.create!(page: @page, content_module: @email_targets, position: 2, layout_container: :sidebar)
  end
end
