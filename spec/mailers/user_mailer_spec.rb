require 'spec_helper'

describe UserMailer, delay_jobs: false do
  let(:user) { create :user, email: "volunteer@getup.org.au", is_member: true }
  let(:email){ UserMailer.deliveries.first }
  
  context ".welcome_to_getup_email sends a welcome email to new users" do
    
    before do
      UserMailer.deliveries.clear
      UserMailer.welcome_to_getup(user)
    end

    it "contains welcome content" do
      expect(email.to.first).to match(/volunteer@getup.org.au/)
      expect(email.subject).to match(/Thanks for joining the GetUp community/)
    end
  end
  context ".welcome_to_getup_email sends a welcome back email to users with associated unsubscriptions" do
    before do
      UserMailer.deliveries.clear
      user.unsubscribe!
      UserMailer.welcome_to_getup(user)
    end

    it "contains welcome back content" do
      expect(email.to.first).to match(/volunteer@getup.org.au/)
      expect(email.subject).to match(/Thanks for coming back to the GetUp community/)
    end
  end
end
