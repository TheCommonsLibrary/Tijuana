require 'spec_helper'

describe DonationTriggerMailer do
  let(:deliveries) { ActionMailer::Base.deliveries }
  let(:email) { ActionMailer::Base.deliveries.first }
  before(:each) { deliveries.clear }

  describe '#expiring_card_email' do
    before{ DonationTriggerMailer.expiring_card_email(create(:donation)).deliver }
    specify{ expect(email.subject).to match(/Your donation payment is expiring/) }
    specify{ expect(email.body).to match(/Thank you for your ongoing support of GetUp./) }
  end

  describe '#donation_failing_email' do
    before{ DonationTriggerMailer.donation_failing_email(create(:donation)).deliver }
    specify{ expect(email.subject).to match(/Your donation is failing/) }
    specify{ expect(email.body).to match(/hasn't been processing recently/) }
  end

  describe '#donation_failing_follow_up_email' do
    before{ DonationTriggerMailer.donation_failing_follow_up_email(create(:donation)).deliver }
    specify{ expect(email.subject).to match(/Your donation is still failing/) }
    specify{ expect(email.body).to match(/Thank you for your ongoing support of GetUp/) }
  end

  describe '#cancellation_warning_email' do
    before{ DonationTriggerMailer.cancellation_warning_email(create(:donation)).deliver }
    specify{ expect(email.subject).to match(/Your donations will soon be cancelled/) }
    specify{ expect(email.body).to match(/Thanks for your ongoing support of GetUp/) }
  end
end