require File.expand_path(File.dirname(__FILE__) + "../../../spec_helper")

describe ListCutter::CampaignRule do

  before do
    @page_1 = create(:page_with_parent)
    @page_2 = create(:page_with_parent)
    @page_3 = create(:page_with_parent)

    @petition_module = create(:petition_module, :public_activity_stream_template => "Someone signed!")
    @email = create(:email)

    @user_a = create(:user)
    @signature_a = create(:petition_signature, :user => @user_a, :content_module => @petition_module)
    UserActivityEvent.action_taken!(@user_a, @page_1, @petition_module, @signature_a, @email)
    UserActivityEvent.action_taken!(@user_a, @page_2, @petition_module, @signature_a, @email)
    UserActivityEvent.action_taken!(@user_a, @page_3, @petition_module, @signature_a, @email)

    @user_b = create(:user)
    @signature_b = create(:petition_signature, :user => @user_b, :content_module => @petition_module)
    UserActivityEvent.action_taken!(@user_b, @page_1, @petition_module, @signature_b, @email)
    UserActivityEvent.action_taken!(@user_b, @page_3, @petition_module, @signature_b, @email)

    @user_c = create(:user)
    @signature_c = create(:petition_signature, :user => @user_c, :content_module => @petition_module)
    UserActivityEvent.action_taken!(@user_c, @page_3, @petition_module, @signature_c, @email)

    @user_d = create(:user)

  end

  def campaign(page)
    page.page_sequence.campaign
  end

  it "should validate a campaign option has been selected" do
    rule = ListCutter::CampaignRule.new

    rule.valid?.should be false
    rule.errors.messages.should == {:campaigns=>["Please select one or more campaigns"]}
  end

  it "should return users that have taken action on a single campaign" do
    rule = ListCutter::CampaignRule.new(:campaigns => [campaign(@page_1).id])
    user_ids = rule.to_relation.all.map(&:id)
    user_ids.uniq.size.should eql 2
    user_ids.should include(@user_a.id, @user_b.id)
  end

  it "should return users that have taken action on a multiple campaigns" do
    rule = ListCutter::CampaignRule.new(:campaigns => [campaign(@page_1).id, campaign(@page_3).id])
    user_ids = rule.to_relation.all.map(&:id)
    user_ids.uniq.size.should eql 3
    user_ids.should include(@user_a.id, @user_b.id, @user_c.id)
  end

  it "should return users that have not taken action on a single campaign" do
    rule = ListCutter::CampaignRule.new(:not => true, :campaigns => [campaign(@page_1).id])
    user_ids = rule.to_relation.all.map(&:id)
    user_ids.uniq.size.should eql 2
    user_ids.should include(@user_c.id, @user_d.id)
  end

  it "should return users that have not taken action on multiple campaigns" do
    rule = ListCutter::CampaignRule.new(:not => true, :campaigns => [campaign(@page_1).id])
    user_ids = rule.to_relation.all.map(&:id)
    user_ids.uniq.size.should eql 2
    user_ids.should include(@user_d.id)
    user_ids.should include(@user_c.id)
  end

  context 'external action' do
    before :each do
      @user_external = create(:user)
      UserActivityEvent.external_action!(@user_external.id, @page_1)
    end

    it "should return users that have taken action or taken external action on a campaign" do
      rule = ListCutter::CampaignRule.new(:campaigns => [campaign(@page_1).id])
      user_ids = rule.to_relation.all.map(&:id)
      user_ids.uniq.size.should eql 3
      user_ids.should include(@user_a.id, @user_b.id, @user_external.id)
    end

    it "should return users that have not taken action or taken external action on a campaign" do
      rule = ListCutter::CampaignRule.new(:not => true, :campaigns => [campaign(@page_1).id])
      user_ids = rule.to_relation.all.map(&:id)
      user_ids.uniq.size.should eql 2
      user_ids.should include(@user_c.id, @user_d.id)
    end
  end

  it "should not include users who have events that are not actions on the specified campaign" do
      UserActivityEvent.quarantined!(@user_d, @email, @page_1, nil)
      rule = ListCutter::CampaignRule.new(:campaigns => [campaign(@page_1).id])
      user_ids = rule.to_relation.all.map(&:id)
      user_ids.uniq.size.should eql 2
      user_ids.should include(@user_a.id, @user_b.id)
  end
end
