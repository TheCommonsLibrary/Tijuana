require File.expand_path(File.dirname(__FILE__) + "../../../spec_helper")
require_relative 'member_value_rule_behaviour.rb'

describe ListCutter::MemberValueTimeRule do
  it_behaves_like "member value rule with time filter", :member_value_time, :member_value_voice, false


  context 'rule' do
    before :each do
      @user1 = create(:user, email:"user1@email.com")
      @user2 = create(:user, email:"user2@email.com")
      @user3 = create(:user, email:"user3@email.com")
      @user4 = create(:user, email:"user4@email.com")

      member_value_for_user2 = create(:member_value_time, current:true, user:@user2, cumulative_value:2, delta_value:2 )
      member_value_for_user3 = create(:member_value_time, current:true, user:@user3, cumulative_value:8, delta_value:8 )
      member_value_for_user4 = create(:member_value_time, current:true, user:@user4, cumulative_value:15, delta_value:15 )
    end

    context 'not negated' do
      context 'with range' do
        it 'should return members with time value 0' do
          rule = ListCutter::MemberValueTimeRule.new(not: false, value_range: '0', lower_limit: '', upper_limit: '')
          user_ids = rule.to_relation.all.map(&:id)
          user_ids.uniq.size.should eql 1
          user_ids.should include(@user1.id)
        end

        it 'should return members with time value between 1 and including 2' do
          rule = ListCutter::MemberValueTimeRule.new(not: false, value_range: '1', lower_limit: '', upper_limit: '')
          user_ids = rule.to_relation.all.map(&:id)
          user_ids.uniq.size.should eql 1
          user_ids.should include(@user2.id)
        end

        it 'should return members with time value greater than or equal to 7' do
          rule = ListCutter::MemberValueTimeRule.new(not: false, value_range: '3', lower_limit: '', upper_limit: '')
          user_ids = rule.to_relation.all.map(&:id)
          user_ids.uniq.size.should eql 2
          user_ids.should include(@user3.id, @user4.id)
        end
      end

      context 'with custom limits' do

        it 'should return members with time value 0 when lower limit and upper limit as 0' do
          rule = ListCutter::MemberValueTimeRule.new(not: false, value_range: '-1', lower_limit: '0', upper_limit: '0')
          user_ids = rule.to_relation.all.map(&:id)
          user_ids.uniq.size.should eql 1
          user_ids.should include(@user1.id)
        end

        it 'should return members with time value 0 when lower limit as blank and upper limit as 0' do
          rule = ListCutter::MemberValueTimeRule.new(not: false, value_range: '-1', lower_limit: '', upper_limit: '0')
          user_ids = rule.to_relation.all.map(&:id)
          user_ids.uniq.size.should eql 1
          user_ids.should include(@user1.id)
        end

        it 'should return members with time value greater than 2' do
          rule = ListCutter::MemberValueTimeRule.new(not: false, value_range: '-1', lower_limit: '3', upper_limit: '')
          user_ids = rule.to_relation.all.map(&:id)
          user_ids.uniq.size.should eql 2
          user_ids.should include(@user3.id, @user4.id)
        end

        it 'should return members with time value greater than 1 and less than 3' do
          rule = ListCutter::MemberValueTimeRule.new(not: false, value_range: '-1', lower_limit: '1', upper_limit: '2')
          user_ids = rule.to_relation.all.map(&:id)
          user_ids.uniq.size.should eql 1
          user_ids.should include(@user2.id)
        end

        it 'should return members with time value less than 450 or no value when lower limit as blank and upper limit as 10' do
          rule = ListCutter::MemberValueTimeRule.new(not: false, value_range: '-1', lower_limit: '', upper_limit: '10')
          user_ids = rule.to_relation.all.map(&:id)
          user_ids.uniq.size.should eql 3
          user_ids.should include(@user1.id, @user2.id, @user3.id)
        end

        it 'should return members with time value less than 450 or no value when lower limit as 0 and upper limit as 10' do
          rule = ListCutter::MemberValueTimeRule.new(not: false, value_range: '-1', lower_limit: '0', upper_limit: '10')
          user_ids = rule.to_relation.all.map(&:id)
          user_ids.uniq.size.should eql 3
          user_ids.should include(@user1.id, @user2.id, @user3.id)
        end

      end
    end
  end
end
