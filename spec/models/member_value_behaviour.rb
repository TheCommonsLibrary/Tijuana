shared_examples_for "member value" do |member_value_type|

  before(:all) do
    @value_type = member_value_type
  end

  describe "default page value types are preserved" do
    it "should sum cumulative activity and record only one current value" do
      take_action(user)
      all_values_recalculated(user)[member_value_type].should == value_figure(1)

      take_action(user)
      all_values_recalculated(user)[member_value_type].should == value_figure(2)

      member_value = MemberValue.where(user_id: user.id, value_type: value_type_str, current: true)
      member_value.count.should == 1
      member_value.first.cumulative_value.should == value_figure(2)
    end
  end

  describe "ignore other activities and value types" do
    it "should not be affected by other value types" do
      take_action(user)
      create(:action_taken_activity, content_module: create(alternate_content_module), user: user)
      all_values_recalculated(user)[member_value_type].should == value_figure(1)
    end
    
    it "should not record member value for activities that are not actions" do
      take_action(user)
      create(:subscribed_activity, user: user)
      create(:unsubscribed_activity, user: user)
      create(:agra_unsubscribed_activity, user: user)
      create(:requested_less_email, user: user)
      create(:email_dropped, user: user)

      result_member_values = {voice: 0, time: 0, money: 0}
      result_member_values[member_value_type] = value_figure(1)
      all_values_recalculated(user).should == result_member_values
    end
  end

  describe "handle inconsistent member value entries" do
    it "should ensure only the current value is marked current" do
      begin
        Timecop.freeze(Time.local(2014, 2, 2, 10, 0, 0))
        first_action = take_action(user)
        first_value = create_member_value(user, first_action, true)
        Timecop.travel(Time.local(2014, 2, 3, 10, 0, 0))
        second_action = take_action(user)
        second_value = create_member_value(user, second_action, true)
        all_values_recalculated(user)

        current_value = MemberValue.where(current: true).where(value_type: value_type_str)
        current_value.count.should == 1
        current_value.first.cumulative_value.should == value_figure(2)
      ensure
        Timecop.return
      end
    end

    it "should ensure cumulative member value is correct" do
      action = take_action(user)
      all_values_recalculated(user)
      value = find_member_value(action)
      value.update_attributes!({cumulative_value: 5})

      results = {voice: 0, time: 0, money: 0}
      results[@value_type] = value_figure(1)
      all_values_recalculated(user).should == results
    end

    it "should ensure orphan member values are removed" do
      action = take_action(user)
      all_values_recalculated(user)
      valid_value = MemberValue.where(user_id: user.id, value_type: value_type_str).first

      create_member_value(user, nil)
      all_values_recalculated(user)
      retrieved_values = MemberValue.where(user_id: user.id, value_type: value_type_str)
      retrieved_values.count.should == 1
      retrieved_values.first.cumulative_value.should == valid_value.cumulative_value
    end
  end

  context "listcutter reads database directly" do
    it "should record member value attributes correctly" do
      page = create(:page_with_parent)
      take_action(user, page)
      all_values_recalculated(user)

      MemberValue.count.should == 1
      member_value = MemberValue.first
      member_value.user.id.should == user.id
      member_value.campaign_id.should == page.page_sequence.campaign.id
      member_value.page_id.should == page.id
      member_value.current.should == true
      member_value.send(:read_attribute, :value_type).should == value_type_str
      member_value.cumulative_value.should == value_figure(1)
      member_value.delta_value.should == value_figure(1)
    end
  end

  describe "::queue_recalculate_for_user", delay_jobs: false do

    before(:each) do
      @user = create(:user)
      @page = create(:page_with_parent)
    end

    context "when recalculate_member_value_after_action is set to true" do
      before(:each) do
        Rails.configuration.stub(:recalculate_member_value_after_action).and_return(true)
      end

      context "with default page member value type" do
        it "should only schedule to recalculate default value for actions taken" do
          assert_value_type_recalculated
          MemberValue.queue_recalculate_for_user(@user, :action_taken, create(value_type_content_module), @page, nil)
        end
      end
    end

    context "when recalculate_member_value_after_action is set to false" do
      it "should not schedule any delayed jobs" do
        Rails.configuration.stub(:recalculate_member_value_after_action).and_return(false)
        MemberValue.should_not_receive(:recalculate_money_value)
        MemberValue.should_not_receive(:recalculate_time_value)
        MemberValue.should_not_receive(:recalculate_voice_value)

        MemberValue.queue_recalculate_for_user(@user, :action_taken, create(value_type_content_module), @page, nil)
      end
    end
  end

  def assert_value_type_recalculated
    {money: :recalculate_money_value, time: :recalculate_time_value, voice: :recalculate_voice_value}.each do |value, method|
      if value == @value_type
        MemberValue.should_receive(method)
      else
        MemberValue.should_not_receive(method)
      end
    end
  end

  def value_type_content_module
    actions = {voice: :petition_module, time: :call_mp_module, money: :donation_module}
    actions[@value_type]
  end

  def action_type
    actions = {voice: :petition_action, time: :call_mp_action, money: :donation_action}
    actions[@value_type]
  end

  def alternate_content_module
    alternate_modules = {time: :donation_module, voice: :call_mp_module, money: :petition_module}
    alternate_modules[@value_type]
  end

  def take_action(user, page=nil)
    page ||= create(:page_with_parent)
    action = create(action_type, user: user, page: page)
    if @value_type == :money
      donation = create(:donation, user: user, amount_in_cents: 1000, page: page)
      create(:transaction, donation: donation, amount_in_cents: 1000) 
    else
      action
    end
  end

  def find_member_value(action_record)
    if action_record.is_a?(UserActivityEvent)
      MemberValue.where(user_activity_event_id: action_record.id).first
    else
      MemberValue.where(transaction_id: action_record.id).first
    end
  end

  def create_member_value(user, action, current=false)
    type = {voice: :member_value_voice, time: :member_value_time, money: :member_value_money}
    if @value_type == :money
      create(type[@value_type], user: user, current: current, financial_transaction: action)
    else
      create(type[@value_type], user: user, current: current, user_activity_event: action)
    end
  end

  def value_figure(value)
    @value_type == :money ? value*1000 : value
  end

  def value_type_str
    @value_type.to_s
  end

end
