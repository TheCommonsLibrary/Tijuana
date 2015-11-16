require 'spec_helper'
require 'rake'

describe "migrate:low_volume_to_quarantine" do
  include_context "rake"

  its(:prerequisites) { should include("environment")  }

  context "with members on low volume" do
    let!(:low_volume_member){ create(:user, low_volume: true, is_member: true) }
    before do
      subject.invoke
      low_volume_member.reload
    end

    it("should take them off low_volume"){ expect(low_volume_member).to_not be_low_volume }
    it("should quarantine them"){ expect(low_volume_member).to be_quarantined }
    it "should create a quarantine event" do
      expect(low_volume_member.user_activity_events.quarantines.where(source: 'migrate').count).to eq(1)
    end
  end

  context "with members who were already quarantined" do
    let!(:already_quarantined_member){ create(:user, is_member: false) }
    before{ UserActivityEvent.quarantined!(already_quarantined_member) }
    before do
      subject.invoke
      already_quarantined_member.reload
    end

    it("should resubscribe them"){ expect(already_quarantined_member).to be_is_member }
    it("should quarantine them"){ expect(already_quarantined_member).to be_quarantined }
    it "should not create another quarantine event" do
      expect(already_quarantined_member.user_activity_events.quarantines.count).to eq(1)
    end
  end
end
