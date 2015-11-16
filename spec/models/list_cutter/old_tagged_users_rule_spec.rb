require File.expand_path(File.dirname(__FILE__) + "../../../spec_helper")

describe ListCutter::OldTaggedUsersRule do
  #TODO - look at campaign_rule_spec as an example of how to write rule tests.
  #This is not a good example as it compares the code to itself, and should be rewritten
  it "should yield a relation mirroring its own parameters" do
    @rule = ListCutter::OldTaggedUsersRule.new(:old_tags => "red, blue ")
    relation = User.where("old_tags regexp '(^|,)red(,|$)'").where("old_tags regexp '(^|,)blue(,|$)'")

    @rule.to_relation.to_sql.should == relation.to_sql
  end

  it "should negate relation" do
    @rule = ListCutter::OldTaggedUsersRule.new(:old_tags => "red, blue ", :not => true)
    relation = User.where("old_tags not regexp '(^|,)red(,|$)'").where("old_tags not regexp '(^|,)blue(,|$)'")

    @rule.to_relation.to_sql.should == relation.to_sql
  end

  it "should validate itself" do
    rule = ListCutter::OldTaggedUsersRule.new

    rule.valid?.should be false
    rule.errors.messages == {:old_tags=>["Please provide one or more tags"]}
  end
end


