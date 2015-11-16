# encoding: UTF-8
require 'spec_helper'

class TestEmailModule < ContentModule
  include EmailModule

  option_fields :dummy
  def defaults; end
end

describe EmailModule do
  before { ActionMailer::Base.deliveries.clear }
  let(:user) { create(:user) }
  let(:page) { create(:page_with_parent) }
  let(:user_email) { create(:user_email) }
  let(:test_email_module) { TestEmailModule.new }

  before do
    test_email_module.stub(:user_email).and_return(user_email)
  end

  it "encodes and decodes emoji properly" do
    user_email.subject = "forgot subject 😕"
    user_email.body = "keep up the great work 😄"

    test_email_module.take_action(user, page)
    Delayed::Worker.new.work_off

    delivery = ActionMailer::Base.deliveries.last
    delivery.should have_subject("forgot subject 😕")
    delivery.should have_body_text("keep up the great work 😄")
  end

  it "removes html tags from user input to ensure we're not a potential attack vector" do
    user_email.body = "test content <img src=\"http://localhost:3000/assets/public/getup_logo.png\" />"

    test_email_module.take_action(user, page)
    Delayed::Worker.new.work_off

    delivery = ActionMailer::Base.deliveries.last
    delivery.should have_body_text("test content")
    delivery.should_not have_body_text("<img src=\"http://localhost:3000/assets/public/getup_logo.png\" />")
  end

  it "does not remove html tags from default body text (campaigner input)" do
    user_email.body = ""
    content = "default content <img src=\"http://localhost:3000/assets/public/getup_logo.png\" />"
    test_email_module.stub(:default_body).and_return(content)

    test_email_module.take_action(user, page)
    Delayed::Worker.new.work_off

    delivery = ActionMailer::Base.deliveries.last
    delivery.should have_body_text("default content <img src=\"http://localhost:3000/assets/public/getup_logo.png\" />")
  end

  it "sends to target if no configuration found for sending to target" do
    test_email_module.send_to_target?.should == true
  end

end
