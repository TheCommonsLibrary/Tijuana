shared_examples_for "member value rule with time filter" do |member_value_type, alternate_member_value_type, is_currency|
  describe "#to_relation" do
    before :each do
      @user_with_no_value = create(:user)
      @user_with_different_value_type = create(:user)
      member_value_for_user_with_different_value_type = create(alternate_member_value_type, current:true, user:@user_with_different_value_type, 
                                                             cumulative_value:9000, delta_value:9000, created_at: Time.local(2014, 3, 1, 1, 0, 0))

      @user_with_early_value = create(:user)
      member_value_for_user_with_early_value = create(member_value_type, current:true, user:@user_with_early_value, 
                                                       cumulative_value:7000, delta_value:7000, created_at: Time.local(2000, 1, 1, 1, 0, 0) )

      @user_with_high_recent_value = create(:user)
      member_value_for_user_with_high_recent_value = create(member_value_type, current:true, user:@user_with_high_recent_value, 
                                                             cumulative_value:5000, delta_value:5000, created_at: Time.local(2014, 3, 1, 1, 0, 0))

      @user_with_early_and_late_entries = create(:user)
      early_member_value = create(member_value_type, current: false, user:@user_with_early_and_late_entries, 
                                   cumulative_value:2000, delta_value:2000, created_at: Time.local(2013, 1, 11, 1, 0, 0))
      late_member_value = create(member_value_type, current: true, user:@user_with_early_and_late_entries, 
                                  cumulative_value:4000, delta_value:2000, created_at: Time.local(2014, 2, 11, 1, 0, 0))

      @user_with_multiple_entries = create(:user)
      early_member_value = create(member_value_type, current: false, user:@user_with_multiple_entries,
                                   cumulative_value:2000, delta_value:2000, created_at: Time.local(2014, 1, 11, 1, 0, 0))
      late_member_value = create(member_value_type, current: true, user:@user_with_multiple_entries,
                                  cumulative_value:4500, delta_value:2500, created_at: Time.local(2014, 3, 11, 1, 0, 0))
    end

    context "within time frame" do
      it "should return members with no value" do
        Timecop.freeze(Time.local(2014, 4, 1, 1, 0, 0)) do
          rule = described_class.new(value_range: '-1', lower_limit: '0', upper_limit: '0', time_limit_months: 4)
          user_ids = rule.to_relation.all.map(&:id)
          user_ids.uniq.size.should == 3
          user_ids.should include(@user_with_early_value.id)
          user_ids.should include(@user_with_no_value.id)
          user_ids.should include(@user_with_different_value_type.id)
        end
      end

      it "should return members who have member value greater than or equal to a particular value" do
        Timecop.freeze(Time.local(2014, 4, 1, 1, 0, 0)) do
          lower_limit = '30'
          lower_limit = (lower_limit.to_i * 100).to_s unless is_currency
          rule = described_class.new(value_range: '-1', lower_limit: lower_limit, upper_limit: '', time_limit_months: 4)
          user_ids = rule.to_relation.all.map(&:id)
          user_ids.uniq.size.should == 2
          user_ids.should include(@user_with_high_recent_value.id)
          user_ids.should include(@user_with_multiple_entries.id)
        end
      end

      it "should return members who have value less than or equal to a particular value" do
        Timecop.freeze(Time.local(2014, 4, 1, 1, 0, 0)) do
          upper_limit = '30'
          upper_limit = (upper_limit.to_i * 100).to_s unless is_currency
          rule = described_class.new(value_range: '-1', lower_limit: '', upper_limit: upper_limit, time_limit_months: 4)
          user_ids = rule.to_relation.all.map(&:id)
          user_ids.uniq.size.should == 4
          user_ids.should include(@user_with_early_value.id)
          user_ids.should include(@user_with_no_value.id)
          user_ids.should include(@user_with_early_and_late_entries.id)
          user_ids.should include(@user_with_different_value_type.id)
        end
      end

      it "should return members who have values within a particular range (inclusive)" do
        Timecop.freeze(Time.local(2014, 4, 1, 1, 0, 0)) do
          lower_limit = '30'
          lower_limit = (lower_limit.to_i * 100).to_s unless is_currency
          upper_limit = '50'
          upper_limit = (upper_limit.to_i * 100).to_s unless is_currency
          rule = described_class.new(value_range: '-1', lower_limit: lower_limit, upper_limit: upper_limit, time_limit_months: 4)
          user_ids = rule.to_relation.all.map(&:id)
          user_ids.uniq.size.should == 2
          user_ids.should include(@user_with_high_recent_value.id)
          user_ids.should include(@user_with_multiple_entries.id)
        end
      end
    end
  end
end

