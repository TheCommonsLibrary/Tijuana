require 'spec_helper'

describe DonationUpgradeModule do
  let(:user){ create :user }
  let(:t){ EmailTrackingToken.encode(user.id, create(:email).id) }
  let(:secure_token){ SecureLinkToken.token(t) }
  let(:params) { {} }
  subject{ DonationUpgradeModule.create!(title: "test") }
  before{ subject.params = params }

  describe "#identified_user" do
    let(:params) { {t: t} }

    it "requires a secure token for identification" do
      expect(subject.identified_user).to eq(nil)
      subject.params.merge! secure_token: secure_token
      expect(subject.identified_user).to eq(user)
    end
  end

  describe "#donation_to_upgrade" do
    let(:donation){ subject.donation_to_upgrade }

    context "with proof tokens" do
      let(:params){ {t: "{TRACKING_HASH|NOT_AVAILABLE}", secure_token: "{SECURE_TOKEN|NOT_AVAILABLE}"} }

      it "returns a dummy donation" do
        expect(donation.user.email).to eq("donationtest@example.com")
      end
    end

    context "with no identified user" do
      let(:params){ {t: nil, secure_token: nil} }

      it "should not find a donation to upgrade" do
        expect(donation).to be_nil
      end
    end

    context "with identified user" do
      let(:params){ {t: t, secure_token: secure_token} }

      context "with no active recurring donations" do
        let!(:one_off){ create(:donation, user: user) }
        let!(:inactive_recurring){ create(:recurring_donation, user: user, active: false) }

        it "should not find a donation to upgrade" do
          expect(donation).to be_nil
        end
      end

      context "with a user set and multiple active credit card recurring donations" do
        let!(:oldest_recurring){ create(:recurring_donation, user: user, created_at: 10.days.ago) }
        let!(:newest_recurring){ create(:recurring_donation, user: user) }

        it "should return the last active recurring donation" do
          expect(donation).to eq newest_recurring
        end
      end
    end
  end

  describe "#take_action" do
    let!(:page){ create(:page_with_parent) }

    context "without a valid token user" do
      let(:params){ {t: "asdf"} }

      it "returns false" do
        expect{
          subject.take_action(user, page, nil, params)
        }.to raise_error "Donation upgrade mismatch"
      end
    end

    context "with a valid token user" do
      let!(:original_amount){ 12 }
      let!(:upgrade_amount){ 20 }
      let!(:donation){ create(:recurring_donation, user: user, amount_in_cents: original_amount * 100) }
      let!(:params){ {t: t, secure_token: secure_token, upgrade_amount_in_dollars: upgrade_amount, donation_id: donation.id} }

      it "should return true" do
        expect(subject.take_action(user, page, nil, params)).to be true
      end

      it "should create a user activity event" do
        subject.take_action(user, page, nil, params)
        uae = user.user_activity_events.last
        expect(uae.page).to eql(page)
        expect(uae.content_module).to eql(subject)
      end

      it "should record the donation amount change" do
        subject.take_action(user, page, nil, params)
        upgrade = DonationUpgrade.where('donation_id = ?', donation.id).first
        expect(upgrade.original_amount_in_cents).to eql(original_amount*100)
        expect(upgrade.upgrade_amount_in_cents).to eql(upgrade_amount*100)
        expect(upgrade.content_module).to eql(subject)
      end

      context "with a custom amount" do
        let!(:upgrade_amount){ 12 }
        before{ params.merge! upgrade_amount_in_dollars: "other", custom_amount_in_dollars: upgrade_amount }

        it "handles custom amounts" do
          subject.take_action(user, page, nil, params)
        end
      end

      context "with an invalid amount" do
        let!(:upgrade_amount){ 0 }
        before{ params.merge! upgrade_amount_in_dollars: "other", custom_amount_in_dollars: upgrade_amount }

        it "should return false" do
          expect(subject.take_action(user, page, nil, params)).to be false
        end

        it "should provide access to the donation upgrade record with the validation errors" do
          create(:donation_upgrade, donation: donation, content_module: subject)
          subject.take_action(user, page, nil, params)
          expect(subject.donation_upgrade.errors.full_messages.grep(/must be greater than 0/)).to_not be_empty
        end
      end

      context "with an amount that can be converted correctly" do
        let!(:upgrade_amount){ '$12.25' }
        before{ params.merge! upgrade_amount_in_dollars: "other", custom_amount_in_dollars: upgrade_amount }

        it "should return true" do
          expect(subject.take_action(user, page, nil, params)).to be true
        end

        it "should provide access to the donation upgrade record with the validation errors" do
          subject.take_action(user, page, nil, params)
          donation.reload
          expect(donation.amount_in_cents).to eq(original_amount * 100 + 1225)
        end
      end
    end
  end

  describe ".for_container?" do
    it "should only be enabled for the sidebar layout" do
      expect(DonationUpgradeModule.for_container?(:aside)).to be false
      expect(DonationUpgradeModule.for_container?(:sidebar)).to be true
    end
  end

  describe "#public_activity_stream_template" do
    it "should be set by default" do
      expect(DonationUpgradeModule.new.public_activity_stream_template).to match(/donated to/)
    end
  end

  describe "#alert_tech_that_the_secure_token_failed" do
    subject{ create(:donation_upgrade_module) }
    it "should send an email to tech with the module details and params" do
      ActionMailer::Base.deliveries = []
      subject.params = {t: 'failed', secure_token: 'to match'}
      subject.alert_tech_that_the_secure_token_failed
      alert = ActionMailer::Base.deliveries.last.body
      expect(alert).to include('failed')
      expect(alert).to include('to match')
      expect(alert).to include(subject.id)
    end
  end
end
