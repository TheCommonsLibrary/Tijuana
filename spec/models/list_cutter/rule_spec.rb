require File.expand_path(File.dirname(__FILE__) + "../../../spec_helper")

describe "ListCutter::Rule" do
  it "should serialize rule options" do
    rule = ListCutter::Rule.new(:email => "test@test.com", :another_param => "blah")
    rule.to_yaml.should match /^---[ ]*\nrule:[ ]*\n  :email: test@test.com\n  :another_param: blah\n$/
  end
end


