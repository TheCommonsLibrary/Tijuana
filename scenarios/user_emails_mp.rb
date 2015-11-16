require File.dirname(__FILE__) + "/scenario_helper.rb"

describe 'User emails MP', type: :feature, js: true do

  context "send email to MP" do
    before(:each) do
      @user = create(:user, email: 'tom.mann@example.com')
      Delayed::Job.delete_all # delete welcome email job
      ActionMailer::Base.deliveries = []
      set_up_pages true
    end

    it "should send an email to the MP and to myself" do
      mp = create(:mp, first_name: 'Nicholas', last_name: 'Angel', party: @party, email: 'Nicholas.Angel.MP@aph.gov.au')
      create(:electorate, postcodes: [@postcode], mps: [mp], jurisdiction: @jurisdiction)

      visit page_path(@campaign.id, @page_sequence.id, @page.id)
      fill_in 'user_email', with: 'tom.mann@example.com'
      user_lookup_complete
      fill_in 'mp_postcode', with: '2000'

      page.should have_content "Your email will go to Nicholas Angel"

      fill_in 'user_email_subject', with: 'Help. Do it.'
      check('user_email_cc_me')
      click_button 'Send your email!'

      page.should have_content 'Thanks for taking action'

      Delayed::Worker.new.work_off
      ActionMailer::Base.deliveries.size.should == 2
      first = ActionMailer::Base.deliveries.first
      last = ActionMailer::Base.deliveries.last
      if first.to.first == @user.email
        last.to.first.should == mp.email
      else
        first.to.first.should == mp.email
        last.to.first.should == @user.email
      end
      first.subject.should == 'Help. Do it.'
      last.subject.should == 'Help. Do it.'
    end

    it "should send an email to the senator" do
      @emp.target = 'MP or Senator'
      @emp.save!

      senator = create(:senator, first_name: 'John', last_name: 'Doe', party: @party, email: 'John.Doe@aph.gov.au')
      create(:electorate, postcodes: [@postcode], jurisdiction: @jurisdiction)
      create(:region, senators: [senator], postcodes: [@postcode], jurisdiction: @jurisdiction)

      visit page_path(@campaign.id, @page_sequence.id, @page.id)
      fill_in 'user_email', with: 'tom.mann@example.com'
      user_lookup_complete
      fill_in 'mp_postcode', with: '2000'

      page.should have_content "Your email will go to Senator John Doe"

      click_button 'Send your email!'

      page.should have_content 'Thanks for taking action'
      Delayed::Worker.new.work_off
      ActionMailer::Base.deliveries.size.should == 1
      ActionMailer::Base.deliveries.first.to.first.should == senator.email
      ActionMailer::Base.deliveries.first.subject.should == 'This is the default subject line'
    end

    it "should send an email to the MP with the default email body and subject" do
      mp = create(:mp, first_name: 'Nicholas', last_name: 'Angel', party: @party, email: 'Nicholas.Angel.MP@aph.gov.au')
      create(:electorate, postcodes: [@postcode], mps: [mp], jurisdiction: @jurisdiction)

      visit page_path(@campaign.id, @page_sequence.id, @page.id)
      fill_in 'user_email', with: 'tom.mann@example.com'
      user_lookup_complete
      fill_in 'mp_postcode', with: '2000'

      page.should have_content "Your email will go to Nicholas Angel"

      click_button 'Send your email!'

      page.should have_content 'Thanks for taking action'
      Delayed::Worker.new.work_off
      ActionMailer::Base.deliveries.size.should == 1
      ActionMailer::Base.deliveries.first.to.first.should == mp.email
      ActionMailer::Base.deliveries.first.subject.should == 'This is the default subject line'
      ActionMailer::Base.deliveries.first.body.parts.first.body == @emp.default_body
    end
  end

  context "does not send email to MP" do
    before(:each) do
      @user = create(:user, email: 'tom.mann@example.com')
      Delayed::Job.delete_all # delete welcome email job
      ActionMailer::Base.deliveries = []
      set_up_pages false
    end

    it "should send an email to myself but not the MP" do
      mp = create(:mp, first_name: 'Nicholas', last_name: 'Angel', party: @party, email: 'Nicholas.Angel.MP@aph.gov.au')
      create(:electorate, postcodes: [@postcode], mps: [mp], jurisdiction: @jurisdiction)

      visit page_path(@campaign.id, @page_sequence.id, @page.id)
      fill_in 'user_email', with: 'tom.mann@example.com'
      user_lookup_complete
      fill_in 'mp_postcode', with: '2000'

      page.should have_content "Your email will go to Nicholas Angel"

      fill_in 'user_email_subject', with: 'Help. Do it.'
      check('user_email_cc_me')
      click_button 'Send your email!'

      page.should have_content 'Thanks for taking action'

      Delayed::Worker.new.work_off
      ActionMailer::Base.deliveries.size.should == 1
      first = ActionMailer::Base.deliveries.first
      first.to.first.should == @user.email
      first.subject.should == 'Help. Do it.'
    end

  end

  def set_up_pages(send_email_to_mp)
    @campaign = create(:campaign)
    @page_sequence = create(:page_sequence, campaign: @campaign, theme: create(:theme))
    @page = create(:page, page_sequence: @page_sequence, position: 1, name: "Landing Page for Walrus MP Email")
    @page2 = create(:page, page_sequence: @page_sequence, position: 2, name: "Thanks for taking action")
    @page.send_thankyou_email = false
    @page.save!

    @emp = create(:email_mp_module, jurisdiction_code: 'FEDERAL', target: 'MP or Senator', send_to_target: send_email_to_mp ? '1' : '0')
    ContentModuleLink.create!(:page => @page, :content_module => @emp, :position => 1, :layout_container => :sidebar)
    @postcode = create(:postcode, number: '2000')
    @party = create(:party)
    @jurisdiction = Jurisdiction.create!(
        code: 'FEDERAL',
        name: 'FEDERAL'
    )
  end
end
