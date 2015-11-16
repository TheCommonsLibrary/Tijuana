require File.expand_path(File.dirname(__FILE__) + "../../../spec_helper")
require_relative 'member_value_rule_behaviour.rb'

describe ListCutter::MemberValueMoneyRule do
  it_behaves_like "member value rule with time filter", :member_value_money, :member_value_time, true

  describe '#to_relation' do
    before :each do
      @user1 = create(:user, email:"user1@email.com")
      @user2 = create(:user, email:"user2@email.com")
      @user3 = create(:user, email:"user3@email.com")
      @user4 = create(:user, email:"user4@email.com")

      member_value_for_user2 = create(:member_value_money, current:true, user:@user2, cumulative_value:9000, delta_value:9000 )
      member_value_for_user3 = create(:member_value_money, current:true, user:@user3, cumulative_value:60000, delta_value:60000 )
      member_value_for_user4 = create(:member_value_money, current:true, user:@user4, cumulative_value:70000, delta_value:70000 )
    end

    context 'with range' do
      it 'should return members with money value of 0' do
        rule = ListCutter::MemberValueMoneyRule.new(not: false, value_range: '0', lower_limit: '', upper_limit: '')
        user_ids = rule.to_relation.all.map(&:id)
        user_ids.uniq.size.should eql 1
        user_ids.should include(@user1.id)
      end

      it 'should return members with money value between 1 to 100' do
        rule = ListCutter::MemberValueMoneyRule.new(not: false, value_range: '1', lower_limit: '', upper_limit: '')
        user_ids = rule.to_relation.all.map(&:id)
        user_ids.uniq.size.should eql 1
        user_ids.should include(@user2.id)
      end

      it 'should return members with money value greater than or equal to 501' do
        rule = ListCutter::MemberValueMoneyRule.new(not: false, value_range: '3', lower_limit: '', upper_limit: '')
        user_ids = rule.to_relation.all.map(&:id)
        user_ids.uniq.size.should eql 2
        user_ids.should include(@user3.id, @user4.id)
      end
    end

    context 'with custom limits' do

      it 'should return members with money value of 0 when lower limit and upper limit are 0' do
        rule = ListCutter::MemberValueMoneyRule.new(not: false, value_range: '-1', lower_limit: '0', upper_limit: '0')
        user_ids = rule.to_relation.all.map(&:id)
        user_ids.uniq.size.should eql 1
        user_ids.should include(@user1.id)
      end

      it 'should return members with money value of 0 when lower limit blank and upper limit is 0' do
        rule = ListCutter::MemberValueMoneyRule.new(not: false, value_range: '-1', lower_limit: '', upper_limit: '0')
        user_ids = rule.to_relation.all.map(&:id)
        user_ids.uniq.size.should eql 1
        user_ids.should include(@user1.id)
      end

      it 'should return members with money value greater or equal to 101' do
        rule = ListCutter::MemberValueMoneyRule.new(not: false, value_range: '-1', lower_limit: '101', upper_limit: '')
        user_ids = rule.to_relation.all.map(&:id)
        user_ids.uniq.size.should eql 2
        user_ids.should include(@user3.id, @user4.id)
      end

      it 'should return members with money value greater or requal to 1 and less than or equal to 100' do
        rule = ListCutter::MemberValueMoneyRule.new(not: false, value_range: '-1', lower_limit: '1', upper_limit: '100')
        user_ids = rule.to_relation.all.map(&:id)
        user_ids.uniq.size.should eql 1
        user_ids.should include(@user2.id)
      end

      it 'should return members with money value less than or equal to 650' do
        rule = ListCutter::MemberValueMoneyRule.new(not: false, value_range: '-1', lower_limit: '', upper_limit: '650')
        user_ids = rule.to_relation.all.map(&:id)
        user_ids.uniq.size.should eql 3
        user_ids.should include(@user1.id, @user2.id, @user3.id)
      end

      it 'should return members with money value less than or equal to 650' do
        rule = ListCutter::MemberValueMoneyRule.new(not: false, value_range: '-1', lower_limit: '0', upper_limit: '650')
        user_ids = rule.to_relation.all.map(&:id)
        user_ids.uniq.size.should eql 3
        user_ids.should include(@user1.id, @user2.id, @user3.id)
      end
    end

  end
end
