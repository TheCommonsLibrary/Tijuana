require File.expand_path(File.dirname(__FILE__) + "../../../spec_helper")

describe ListCutter::ExcludeLowVolumeMembersRule do

  def new_rule(options={})
    ListCutter::ExcludeLowVolumeMembersRule.new
  end

  it "should generate relation" do
    new_rule.to_relation.to_sql.
      should include("users.low_volume = false")
  end

end


