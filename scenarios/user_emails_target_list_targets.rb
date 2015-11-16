require File.dirname(__FILE__) + "/scenario_helper.rb"

describe "User emails target list targets", type: :feature, js: true do

  context "send email to targets" do
    before(:each) do
      set_up_pages true
      @user = create(:user, email: 'user@user.com')
      Delayed::Job.delete_all # delete welcome email job
      ActionMailer::Base.deliveries = []
    end

    it "should send an email with default content to the target super fund and CC the user" do
      visit page_path(@campaign.id, @page_sequence.id, @page.id)
      fill_in 'user_email', with: @user.email
      user_lookup_complete
      fill_in 'user_first_name', with: 'Bill'
      fill_in 'user_last_name', with: 'Bill'
      select('Brisbane North - City-North News', from: 'list_target')

      check('user_email_cc_me')
      page.find('.btn-primary').click
      page.should have_content 'Thanks for taking action'

      Delayed::Worker.new.work_off
      ActionMailer::Base.deliveries.size.should == 2
      first = ActionMailer::Base.deliveries.first
      last = ActionMailer::Base.deliveries.last
      if first.to.first == @user.email
        last.to.first.should == @target_email
        target_email = last
      else
        first.to.first.should == @target_email
        last.to.first.should == @user.email
        target_email = first
      end
      first.subject.should == @email_subject
      last.subject.should == @email_subject

      # Load the tracking pixel and confirm the data is logged
      tracking_link = target_email.html_part.body.match(/img src="(.*)"/)[1]
      visit URI.parse(tracking_link).path
      tracking_log = EmailTargetTrackingLog.last
      tracking_log.user_email.user.should == @user
      tracking_log.user_email.targets.should == @target_email
      tracking_log.ip.should == '127.0.0.1'
    end

    it "should send an email to target super fund with talking point and user supplied content and no cc to self" do
      visit page_path(@campaign.id, @page_sequence.id, @page.id)
      fill_in 'user_email', with: @user.email
      user_lookup_complete
      fill_in 'user_first_name', with: 'Bill'
      fill_in 'user_last_name', with: 'Bill'
      select('Brisbane North - City-North News', from: 'list_target')
      fill_in 'user_email_subject', with: 'new subject line'
      fill_in 'user_email_body', with: 'new email body here'
      page.find('.content-module.accordion-module.talking-points > .accordion-heading > a').click
      page.find('.btn-add').click

      page.find('.btn-primary').click
      page.should have_content 'Thanks for taking action'

      Delayed::Worker.new.work_off
      ActionMailer::Base.deliveries.size.should == 1
      ActionMailer::Base.deliveries.first.to.first.should == @target_email
      ActionMailer::Base.deliveries.first.subject.should == 'new subject line'
      ActionMailer::Base.deliveries.first.encoded.should include('new email body here')
      ActionMailer::Base.deliveries.first.encoded.should include('100% of Australians think this is wrong')
    end
  end

  context "emails are not sent to targets" do
    before(:each) do
      set_up_pages false
      @user = create(:user, email: 'user@user.com')
      Delayed::Job.delete_all # delete welcome email job
      ActionMailer::Base.deliveries = []
    end

    it "should send an email to the user but not to the target" do
      visit page_path(@campaign.id, @page_sequence.id, @page.id)
      fill_in 'user_email', with: @user.email
      user_lookup_complete
      fill_in 'user_first_name', with: 'Bill'
      fill_in 'user_last_name', with: 'Bill'
      select('Brisbane North - City-North News', from: 'list_target')

      check('user_email_cc_me')
      page.find('.btn-primary').click
      page.should have_content 'Thanks for taking action'

      Delayed::Worker.new.work_off
      ActionMailer::Base.deliveries.size.should == 1
      email = ActionMailer::Base.deliveries.first
      email.to.first.should == @user.email
      email.subject.should == @email_subject
    end
  end

private

  def set_up_pages(send_to_target)
    @campaign = create(:campaign)
    @page_sequence = create(:page_sequence, campaign: @campaign)
    @page = create(:page, page_sequence: @page_sequence, position: 1)
    @page2 = create(:page, page_sequence: @page_sequence, position: 2, name: "Thanks for taking action")
    @postcode = create(:postcode)
    @target_email = 'editorial@citynorthnews.com.au'
    @email_subject = 'This is the default subject...'

    target_list_targets = TargetListModule.create!(
        :title => 'Target List Target',
        :content => 'This is the content',
        :default_subject => @email_subject,
        :default_body => 'This is the default body',
        :target_email_list => 'editorial@citynorthnews.com.au | Brisbane North - City-North News',
        :send_to_target => send_to_target ? '1' : '0'
    )
    ContentModuleLink.create!(page: @page, content_module: target_list_targets, position: 1, layout_container: :sidebar)
    talking_point = TalkingPoint.create!(short_description: 'this is not right', long_description: '100% of Australians think this is wrong.', content_module_id: target_list_targets.id)
  end
end
