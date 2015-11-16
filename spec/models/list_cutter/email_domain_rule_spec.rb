require File.expand_path(File.dirname(__FILE__) + "../../../spec_helper")

describe ListCutter::EmailDomainRule do
  #TODO - look at campaign_rule_spec as an example of how to write rule tests.
  #This is not a good example as it compares the code to itself, and should be rewritten
  before(:each) do
    @rule = ListCutter::EmailDomainRule.new(:domain => "test@test.com")
  end

  it "should yield a relation mirroring its own parameters" do
    relation = User.where(["email like ?", "%@test.com"])

    @rule.to_relation.to_sql.should == relation.to_sql
  end

  it "should yield correct relation even without the @ sign" do
    relation = User.where(["email like ?", "%@test.com"])

    rule = ListCutter::EmailDomainRule.new(:domain => "test.com")
    rule.to_relation.to_sql.should == relation.to_sql
  end
  
  it "should negate relation" do
    relation = User.where(["email not like ?", "%@test.com"])

    rule = ListCutter::EmailDomainRule.new(:domain => "test.com", :not => true)
    rule.to_relation.to_sql.should == relation.to_sql
  end

  it "should validate itself" do
    rule = ListCutter::EmailDomainRule.new

    rule.valid?.should be false
    rule.errors.messages == {:domain=>["Please specify the email server"]}
  end
end


