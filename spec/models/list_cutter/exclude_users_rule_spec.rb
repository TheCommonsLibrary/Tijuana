require File.expand_path(File.dirname(__FILE__) + "../../../spec_helper")

describe ListCutter::ExcludeUsersRule do
  #TODO - look at campaign_rule_spec as an example of how to write rule tests.
  #This is not a good example as it compares the code to itself, and should be rewritten
  it "should yield a relation mirroring its own parameters" do
    rule = ListCutter::ExcludeUsersRule.new(:push_id => 5)
    join_fragment = <<-JOIN.strip_heredoc
      LEFT OUTER JOIN push_5 push_events
        ON users.id = push_events.user_id
        AND push_events.activity = 'email_sent'
    JOIN
    relation = User.joins(join_fragment).where("push_events.user_id IS NULL")

    rule.to_relation.to_sql.should == relation.to_sql
  end
end
