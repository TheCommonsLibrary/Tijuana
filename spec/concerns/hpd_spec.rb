require 'spec_helper'

describe Hpd do
  let(:user){ create(:user) }
  let(:min){ 5 }
  let(:max){ 300 }
  let(:ratio){ 1.4 }
 
  describe ".hpd" do
    context "user without a hpd" do
      specify{ expect(user.hpd(min, max, ratio)).to be_nil }
    end

    context "with a hpd" do
      let(:donation){ create(:donation, user: user, frequency: 'one_off') }

      context "in range" do
        let!(:transaction){ create(:transaction, amount_in_cents: 3300, donation: donation) }
        it "should return a rounded value that is hpd * ratio" do
          expect(user.hpd(min, max, ratio)).to eq(46)
        end
      end
    
      context "below min" do
        let!(:transaction){ create(:transaction, amount_in_cents: 300, donation: donation) }
        it "should return a rounded value that is min * ratio" do
          expect(user.hpd(min, max, ratio)).to eq(7)
        end
      end
    
      context "above max" do
        let!(:transaction){ create(:transaction, amount_in_cents: 100100, donation: donation) }
        it "should return a rounded value that is max * ratio" do
          expect(user.hpd(min, max, ratio)).to eq(420)
        end
      end
    end
  end

  describe ".hpd_amounts" do
    let!(:email){ create(:email) }

    context "with a member without a HPD" do
      it "should provide a html list of amounts" do
        expect(user.hpd_amounts(email.id, 'https://www.getup.org.au/redirect')).to be_include('30')
      end

      it "should include a link to the other amount" do
        token = EmailTrackingToken.encode(user.id, email.id)
        expect(user.hpd_amounts(email.id, 'https://www.getup.org.au/redirect')).to be_include("href=\"https://www.getup.org.au/redirect?t=#{token}\"")
      end
    end

    context "with a member with a HPD" do
      let(:donation){ create(:donation, user: user, frequency: 'one_off') }
      let!(:transaction){ create(:transaction, amount_in_cents: 3300, donation: donation) }

      it "should provide a html list of amounts" do
        expect(user.hpd_amounts(email.id, 'https://www.getup.org.au/redirect')).to be_include('66')
      end

      it "should append the token to the list amounts" do
        token = EmailTrackingToken.encode(user.id, email.id)
        expect(user.hpd_amounts(email.id, 'https://www.getup.org.au/redirect')).to be_include("https://www.getup.org.au/redirect?t=#{token}")
      end

      it "should append the amount to the link" do
        token = EmailTrackingToken.encode(user.id, email.id)
        expect(user.hpd_amounts(email.id, 'https://www.getup.org.au/redirect')).to be_include("https://www.getup.org.au/redirect?t=#{token}&a=66")
      end
    end
  end

  describe ".hpd_with_page_ids" do
    let!(:user){ create(:user) }
    let!(:page){ create(:page_with_parent) }

    context "with a user with no donations" do
      specify{ expect(user.hpd_for_page_ids([page.id], 50)).to be_nil }
    end

    context "with a donation under the max" do
      let!(:donation){ create(:donation, page: page, amount_in_cents: 1000, user: user) }
      specify{ expect(user.hpd_for_page_ids([page.id], 50)).to eq(10) }
    end

    context "with a donation above the max" do
      let!(:donation){ create(:donation, page: page, amount_in_cents: 1000, user: user) }
      specify{ expect(user.hpd_for_page_ids([page.id], 5)).to eq(5) }
    end
  end
end
