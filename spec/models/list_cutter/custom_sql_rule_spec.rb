require File.expand_path(File.dirname(__FILE__) + "../../../spec_helper")

describe ListCutter::CustomSqlRule do
  before(:each) do
    @custom_sql = "SELECT u.id FROM users u WHERE country_iso = 'AU'"
    @rule = ListCutter::CustomSqlRule.new(:custom_sql => @custom_sql)
  end

  it "should validate itself" do
    rule = ListCutter::CustomSqlRule.new
    rule.valid?.should be false
    rule.errors.messages == {:custom_sql => ["Please specify a some custom SQL"]}
  end

  it "should not add a MySql error if there are other errors present" do
    #doesn't start with select, and ends in a ';'
    rule = ListCutter::CustomSqlRule.new(:custom_sql => "dSELECT u.id FROM users u WHERE country_is = 'AU';")
    rule.valid?.should be false
    rule.errors.messages.should == {
      :custom_sql => ['Should start with a SELECT statement', 'Should not contain the character ";"']
      }
  end

  describe 'to_relation' do
    before :each do
      @user1 = create(:user, country_iso: 'AU')
      @user2 = create(:user, country_iso: 'US')
    end

    it 'should create relation which select users asked by custom sql' do
      relation = User.joins("INNER JOIN (\n#{@custom_sql}\n) custom_user_query ON custom_user_query.id = users.id")

      result = @rule.to_relation
      result.to_sql.should == relation.to_sql

      user_ids = result.map(&:id)
      user_ids.uniq.size.should == 1
      user_ids.should include(@user1.id)
      user_ids.should_not include(@user2.id)
    end

    it 'should create relation which select users that have not asked by custom sql' do
      @rule = ListCutter::CustomSqlRule.new(custom_sql: @custom_sql, not: true)

      relation = User.joins("LEFT OUTER JOIN (\n#{@custom_sql}\n) custom_user_query ON custom_user_query.id = users.id").where("custom_user_query.id IS NULL")

      result = @rule.to_relation
      result.to_sql.should == relation.to_sql

      user_ids = result.map(&:id)
      user_ids.uniq.size.should == 1
      user_ids.should include(@user2.id)
      user_ids.should_not include(@user1.id)
    end
  end
end
