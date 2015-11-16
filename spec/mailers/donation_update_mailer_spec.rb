require 'spec_helper'

describe DonationUpdaterMailer do
  let(:email){ DonationUpdaterMailer.deliveries.first }
  let(:user){ create(:user) }

  describe ".donation_update_email" do
    context "with new amount and frequncy greater than old amounts and frequency" do
      before do
        DonationUpdaterMailer.donation_update_email(user, 10, 'monthly', 5, 'weekly').deliver
      end

      specify{ expect(email.subject).to match(/Thanks for increasing your Crew support/) }
      specify{ expect(email.body).to match(/Thank you so much for increasing your GetUp Crew support/) }
    end
    context "with new amount and frequncy smaller than or equal to old amounts and frequency" do
      before do
        DonationUpdaterMailer.donation_update_email(user, 5, 'weekly', 10, 'monthly').deliver
      end

      specify{ expect(email.subject).to match(/Your Crew donation has been updated/) }
      specify{ expect(email.body).to match(/Thanks for being part of the GetUp Crew/) }
    end

    it 'should use the financial_contact_name' do
      DonationUpdaterMailer.donation_update_email(user, 5, 'weekly', 10, 'monthly').deliver
      expect(email.body).to include(AppConstants.financial_contact_name)
    end
  end
end
