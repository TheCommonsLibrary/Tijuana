require File.expand_path(File.dirname(__FILE__) + "../../../spec_helper")

describe ListCutter::CountryRule do
  before(:each) do
    @rule = ListCutter::CountryRule.new(:country_iso => "BR")
  end

  #TODO - look at campaign_rule_spec as an example of how to write rule tests.
  #This is not a good example as it compares the code to itself, and should be rewritten
  it "should yield a relation mirroring its own parameters" do
    relation = User.where(["country_iso = ?", "BR"])

    @rule.to_relation.to_sql.should == relation.to_sql
  end

  it "should negate relation" do
    relation = User.where(["country_iso != ?", "BR"])

    @rule = ListCutter::CountryRule.new(:country_iso => "BR", :not => true)
    @rule.to_relation.to_sql.should == relation.to_sql
  end

  it "should validate itself" do
    rule = ListCutter::CountryRule.new

    rule.valid?.should be false
    rule.errors.messages == {:country_iso=>["Please specify a country code"]}
  end
end


