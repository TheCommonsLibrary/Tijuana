require File.dirname(__FILE__) + "/scenario_helper.rb"

describe "User pledges to email targets", type: :feature, js: true do

  context "with a user pledging to contact extra people" do

    before{ set_up_pages }
    let!(:pledges){ 4.times.map{|index| ["target#{index}@email.com", "Fox #{index}"] } }

    it "should send an email to each of the targets" do
      visit page_path(@campaign.id, @page_sequence.id, @page.id)
      fill_in 'user_email', with: @user.email
      user_lookup_complete
      fill_in 'user_first_name', with: 'Bill'

      3.times do |index|
        pledge = pledges[index]
        fill_in "target_email_#{index}", with: pledge.first
        fill_in "target_name_#{index}", with: pledge.last
      end
      extra_pledge = pledges.last
      find('#add-extra-pledge').click
      fill_in "target_email_3", with: extra_pledge.first
      fill_in "target_name_3", with: extra_pledge.last
      

      page.find('.btn-primary').click
      page.should have_content 'Thanks for taking action'

      Delayed::Worker.new.work_off
      ActionMailer::Base.deliveries.size.should == pledges.length

      pledges.each_with_index do |pledge, index|
        target_email, target_name = pledge
        email = ActionMailer::Base.deliveries[index]
        email.to.should == [target_email]

        email_pledges = EmailPledge.where(user_id: @user.id, content_module_id: @email_pledges.id).select{|email_pledge|
          email_pledge.user_email.targets == target_email
        }
        email_pledges.length.should == 1
        email_pledge = email_pledges.first
        email_pledge.target_email.should == target_email
        email_pledge.target_name.should == target_name
      end
    end
  end

  private

  def set_up_pages
    @user = create(:user, email: 'user@user.com')
    Delayed::Job.delete_all # delete welcome email job
    ActionMailer::Base.deliveries = []
    @campaign = create(:campaign)
    @page_sequence = create(:page_sequence, campaign: @campaign, theme: create(:theme))
    @page = create(:page, page_sequence: @page_sequence, position: 1)
    @page2 = create(:page, page_sequence: @page_sequence, position: 2, name: "Thanks for taking action")
    @postcode = create(:postcode)
    @email_subject = 'This is the default subject...'

    @email_pledges = EmailPledgesModule.create!(
        title: 'Email target',
        content: 'This is the content',
        default_subject: @email_subject,
        default_body: 'This is the default body',
        pro_forma_prefix: 'prefix goes here'
    )
    ContentModuleLink.create!(page: @page, content_module: @email_pledges, position: 1, layout_container: :sidebar)
    @email_pledges.talking_points << TalkingPoint.new(short_description: 'First Point', long_description: "First long description")
  end
end
