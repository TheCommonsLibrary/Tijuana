require File.expand_path(File.dirname(__FILE__) + "../../../spec_helper")

describe ListCutter::TokensRule do
  before(:each) do
    @user1 = create(:user)
    @user2 = create(:user)
    @user1_token = EmailTrackingToken.encode(@user1.id, 101)
    @user2_token = EmailTrackingToken.encode(@user2.id, 101)
    @broken_token = "asdf234sef2345sef"
  end

  def new_rule(options={})
    ListCutter::TokensRule.new(
      {:tokens_string => "#{@user1_token} \n\r #{@user2_token} \r\n#{@broken_token}"}.
      merge(options))
  end

  it "should generate relation" do
    new_rule.to_relation.to_sql.
      should include("users.id in (#{@user1.id},#{@user2.id})")
  end

  it "should negate relation" do
    new_rule(:not => true).to_relation.to_sql.
      should include("users.id not in (#{@user1.id},#{@user2.id})")
  end

  it "should show active/inactive" do
    new_rule(:tokens_string => '').active?.should be false
    new_rule.active?.should be true
  end

  it "should validate presence" do
    new_rule.valid? should be_truthy
    new_rule(:tokens_string=>'').valid?.should be false
  end
end


