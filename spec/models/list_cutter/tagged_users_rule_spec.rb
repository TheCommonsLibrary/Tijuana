require File.expand_path(File.dirname(__FILE__) + "../../../spec_helper")

describe ListCutter::TaggedUsersRule do
  before(:each) do
    @user_tagged_with_first = create(:user)
    @user_tagged_with_first.tag_list.add("first")
    @user_tagged_with_first.save!

    @user_tagged_with_second = create(:user)
    @user_tagged_with_second.tag_list.add("second")
    @user_tagged_with_second.save!
  end

  it "should generate a query to match users tagged with specific tag" do
    rule = ListCutter::TaggedUsersRule.new(:tags => "first")
    rule.to_relation.to_sql.should include("taggable_type = 'User'")
    rule.to_relation.to_sql.should include("JOIN taggings")

    user_ids = rule.to_relation.map(&:id)
    user_ids.should include(@user_tagged_with_first.id)
    user_ids.should_not include(@user_tagged_with_second.id)
  end

  it "should generate a query to match multiple tags" do
    rule = ListCutter::TaggedUsersRule.new(:tags => "first, second")
    rule.to_relation.to_sql.should include("taggable_type = 'User'")
    rule.to_relation.to_sql.should include("JOIN taggings")

    user_ids = rule.to_relation.map(&:id)
    user_ids.should include(@user_tagged_with_first.id)
    user_ids.should include(@user_tagged_with_second.id)
  end

  it "should validate whether the tags entered by the user exists" do
    rule = ListCutter::TaggedUsersRule.new(:tags => "i-dont-exist")
    rule.valid?.should be false
  end

  it "should ignore leading and training whitespace in the tag list" do
    rule = ListCutter::TaggedUsersRule.new(:tags => " first ")
    rule.to_relation.to_sql.should include("taggable_type = 'User'")
    rule.to_relation.to_sql.should include("JOIN taggings")

    user_ids = rule.to_relation.map(&:id)
    user_ids.should include(@user_tagged_with_first.id)
    user_ids.should_not include(@user_tagged_with_second.id)
  end


  it "should generate query to match users not tagged with specific tag" do
    rule = ListCutter::TaggedUsersRule.new(:tags => "second", not: true)

    user_ids = rule.to_relation.map(&:id)
    user_ids.should include(@user_tagged_with_first.id)
    user_ids.should_not include(@user_tagged_with_second.id)
  end

  it "should validate itself" do
    rule = ListCutter::TaggedUsersRule.new(tags: '')

    rule.valid?.should be false
    rule.errors.messages == {:tags=>["Please provide one or more tags"]}
  end
end


