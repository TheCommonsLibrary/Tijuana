require File.expand_path(File.dirname(__FILE__) + "../../../spec_helper")

describe ListCutter::EmailAddressesRule do

  def new_rule(options={})
    ListCutter::EmailAddressesRule.new(
      {:email_addresses_string => "james@g.org \n\r richard@g.org"}.
      merge(options))
  end

  it "should generate relation" do
    new_rule.to_relation.to_sql.
      should include("users.email in ('james@g.org','richard@g.org')")
  end

  it "should negate relation" do
    new_rule(:not => true).to_relation.to_sql.
      should include("users.email not in ('james@g.org','richard@g.org')")
  end

  it "should show active/inactive" do
    new_rule(:email_addresses_string => '').active?.should be false
    new_rule.active?.should be true
  end

  it "should validate presence" do
    new_rule.valid? should be_truthy
    new_rule(:email_addresses_string=>'').valid?.should be false
  end
end


