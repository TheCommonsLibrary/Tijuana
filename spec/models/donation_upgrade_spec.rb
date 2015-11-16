require 'spec_helper'

describe DonationUpgrade do
  context "with text in the upgrade amount" do
    subject{ build(:donation_upgrade, upgrade_amount_in_cents: 'invalid') }
    it "should not validate the amount" do
      expect(subject).to_not be_valid
    end
  end

  context "with a non positive upgrade amount" do
    subject{ build(:donation_upgrade, upgrade_amount_in_cents: -10) }
    it "should not validate the amount" do
      expect(subject).to_not be_valid
    end
  end
end
