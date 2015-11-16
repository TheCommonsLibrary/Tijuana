require File.expand_path(File.dirname(__FILE__) + "../../../spec_helper")
require_relative 'member_value_rule_behaviour.rb'

describe ListCutter::MemberValueVoiceRule do
  it_behaves_like "member value rule with time filter", :member_value_voice, :member_value_money, false

  context 'rule' do
    before :each do
      @user1 = create(:user, email:"user1@email.com")
      @user2 = create(:user, email:"user2@email.com")
      @user3 = create(:user, email:"user3@email.com")
      @user4 = create(:user, email:"user4@email.com")

      member_value_for_user2 = create(:member_value_voice, current:true, user:@user2, cumulative_value:4, delta_value:4 )
      member_value_for_user3 = create(:member_value_voice, current:true, user:@user3, cumulative_value:21, delta_value:21 )
      member_value_for_user4 = create(:member_value_voice, current:true, user:@user4, cumulative_value:30, delta_value:30 )
    end

    context 'not negated' do
      context 'with range' do
        it 'should return members with voice value 0' do
          rule = ListCutter::MemberValueVoiceRule.new(not: false, value_range: '0', lower_limit: '', upper_limit: '')
          user_ids = rule.to_relation.all.map(&:id)
          user_ids.uniq.size.should eql 1
          user_ids.should include(@user1.id)
        end

        it 'should return members with voice value between 1 to 5' do
          rule = ListCutter::MemberValueVoiceRule.new(not: false, value_range: '1', lower_limit: '', upper_limit: '')
          user_ids = rule.to_relation.all.map(&:id)
          user_ids.uniq.size.should eql 1
          user_ids.should include(@user2.id)
        end

        it 'should return members with voice value greater than or equal to 20' do
          rule = ListCutter::MemberValueVoiceRule.new(not: false, value_range: '3', lower_limit: '', upper_limit: '')
          user_ids = rule.to_relation.all.map(&:id)
          user_ids.uniq.size.should eql 2
          user_ids.should include(@user3.id, @user4.id)
        end
      end

      context 'with custom limits' do

        it 'should return members with voice value 0 when lower limit and upper limit as 0' do
          rule = ListCutter::MemberValueVoiceRule.new(not: false, value_range: '-1', lower_limit: '0', upper_limit: '0')
          user_ids = rule.to_relation.all.map(&:id)
          user_ids.uniq.size.should eql 1
          user_ids.should include(@user1.id)
        end

        it 'should return members with voice value 0 when lower limit as blank and upper limit as 0' do
          rule = ListCutter::MemberValueVoiceRule.new(not: false, value_range: '-1', lower_limit: '', upper_limit: '0')
          user_ids = rule.to_relation.all.map(&:id)
          user_ids.uniq.size.should eql 1
          user_ids.should include(@user1.id)
        end

        it 'should return members with voice value greater than 5' do
          rule = ListCutter::MemberValueVoiceRule.new(not: false, value_range: '-1', lower_limit: '6', upper_limit: '')
          user_ids = rule.to_relation.all.map(&:id)
          user_ids.uniq.size.should eql 2
          user_ids.should include(@user3.id, @user4.id)
        end

        it 'should return members with voice value greater than 1 and less than 6' do
          rule = ListCutter::MemberValueVoiceRule.new(not: false, value_range: '-1', lower_limit: '1', upper_limit: '5')
          user_ids = rule.to_relation.all.map(&:id)
          user_ids.uniq.size.should eql 1
          user_ids.should include(@user2.id)
        end

        it 'should return members with voice value less than 25 or no value when lower limit as blank and upper limit as 25' do
          rule = ListCutter::MemberValueVoiceRule.new(not: false, value_range: '-1', lower_limit: '', upper_limit: '25')
          user_ids = rule.to_relation.all.map(&:id)
          user_ids.uniq.size.should eql 3
          user_ids.should include(@user1.id, @user2.id, @user3.id)
        end

        it 'should return members with voice value less than 25 or no value when lower limit as 0 and upper limit as 25' do
          rule = ListCutter::MemberValueVoiceRule.new(not: false, value_range: '-1', lower_limit: '0', upper_limit: '25')
          user_ids = rule.to_relation.all.map(&:id)
          user_ids.uniq.size.should eql 3
          user_ids.should include(@user1.id, @user2.id, @user3.id)
        end

      end
    end
  end
end
