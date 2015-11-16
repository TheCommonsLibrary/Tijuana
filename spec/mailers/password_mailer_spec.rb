require 'spec_helper'

describe PasswordMailer do
  context ".deliver_all_admins_notification sends an email to all admins" do
    before do
      PasswordMailer.deliveries.clear
      User.create email: "volunteer@getup.org.au", is_volunteer: true
      admin = User.create email: "admin@getup.org.au", is_admin: true
      PasswordMailer.deliver_all_admins_notification(admin).deliver
      @email = PasswordMailer.deliveries.first
    end

    it "contains a list of all admins & volunteers" do
      @email.body.should match(/admin@getup.org.au/)
      @email.body.should match(/volunteer@getup.org.au/)
    end
  end
end
