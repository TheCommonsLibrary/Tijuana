require File.expand_path(File.dirname(__FILE__) + '../../spec_helper')

describe UserMailer do
  before(:each) do
    ActionMailer::Base.deliveries = []
  end

  it "#welcome_to_getup" do
    user = create(:user, :is_member => true)
    ActionMailer::Base.should have(0).deliveries

    UserMailer.welcome_to_getup(user)
    ActionMailer::Base.should have(0).deliveries

    Delayed::Worker.new.work_off
    ActionMailer::Base.should have(1).deliveries
    mail = ActionMailer::Base.deliveries.last
    mail.parts.length.should be(2)

    mail.parts[0].should have_body_text(/#{user.first_name}/)
    mail.parts[1].should have_body_text(/#{user.first_name}/)

    mail.should have_subject(/Thanks for joining the GetUp community!/)
    mail.should deliver_to(user.email)
  end

  it "#welcome_to_community_run" do
    user = create(:user, :is_member => true)
    UserMailer.welcome_to_community_run(user)
    ActionMailer::Base.should have(0).deliveries

    Delayed::Worker.new.work_off
    ActionMailer::Base.should have(1).deliveries
    mail = ActionMailer::Base.deliveries.last
    mail.should have_body_text(/#{user.first_name}/)
    mail.should have_subject(/CommunityRun/)
    mail.should deliver_to(user.email)
  end
end
