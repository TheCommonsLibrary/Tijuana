require File.expand_path(File.dirname(__FILE__) + "../../../spec_helper")

describe ListCutter::ExcludeQuarantineRule do
  describe "#to_relation" do
    let!(:quarantined_user) {create(:user)}
    let!(:regular_member) {create(:user)}
    before {create(:quarantine, user_id: quarantined_user.id) }
    let!(:rule) {ListCutter::ExcludeQuarantineRule.new}

    it "should exclude members in quarantine" do
      rule.to_relation.count.should == 1
      rule.to_relation.first.should == regular_member
    end
  end
end
