require_relative "../../spec_helper"

describe ListCutter::PillarRule do
  (1..3).each do |n|
    let(:"pillar#{n}") { Campaign.accounts_keys[n] }
    let(:"pa#{n}") { create(:petition_action) }
    let(:"campaign#{n}") { send("pa#{n}").page.page_sequence.campaign }
    let(:"user#{n}") { send("pa#{n}").user }

    before do
      campaign = send("campaign#{n}")
      pillar = send("pillar#{n}")
      campaign.accounts_key = pillar
      campaign.save!
    end
  end

  let(:user_external) { create(:user) }
  before { UserActivityEvent.external_action!(user_external.id, pa1.page) }

  it "should validate a pillar option has been selected" do
    rule = ListCutter::PillarRule.new
    expect(rule.valid?).to be(false)
    expect(rule.errors.messages).to eq({pillars: ["Please select one or more pillars"]})
  end

  it "should not include users who have non-action events on the campaigns" do
    UserActivityEvent.quarantined!(create(:user), nil, pa1.page)
    rule = ListCutter::PillarRule.new(pillars: [pillar1])
    expect(rule.to_relation.to_a).to match_array([user1, user_external])
  end

  it "should return users that have taken action on a single pillar's campaigns" do
    rule = ListCutter::PillarRule.new(pillars: [pillar1])
    expect(rule.to_relation.to_a).to match_array([user1, user_external])
  end

  it "should return users that have taken action on multiple pillars' campaigns" do
    rule = ListCutter::PillarRule.new(pillars: [pillar1, pillar2])
    expect(rule.to_relation.to_a).to match_array([user1, user2, user_external])
  end

  context "when negated" do
    it "should return users that have not taken action on a single pillar's campaigns" do
      rule = ListCutter::PillarRule.new(not: true, pillars: [pillar1])
      expect(rule.to_relation.to_a).to match_array([user2, user3])
    end

    it "should return users that have not taken action on multiple pillars' campaigns" do
      rule = ListCutter::PillarRule.new(not: true, pillars: [pillar1, pillar2])
      expect(rule.to_relation.to_a).to match_array([user3])
    end

    context "with someone that has taken action on selected and non-selected campaign" do
      let!(:pillar_1_petition){ create(:petition_action, user: user3, page: campaign1.page_sequences.first.pages.first) }
      it "should exclude them" do
        rule = ListCutter::PillarRule.new(not: true, pillars: [pillar1])
        expect(rule.to_relation.to_a).to match_array([user2])
      end
    end
  end
end
