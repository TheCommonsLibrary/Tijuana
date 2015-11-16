shared_examples_for "monovalue type" do |member_value_type|

  before(:all) do
    @value_type = member_value_type
  end

  describe "page overrides default value types" do
    it "should recalculate values as override type when they are updated" do
      page = create(:page_with_parent, member_value_type: other_type.to_s)
      create(action_type, page: page, user: user)
      result_values = {voice: 0, time: 0, money: 0}
      result_values[other_type] = 1
      all_values_recalculated(user).should == result_values

      create(action_type, page: page, user: user)
      result_values[other_type] = 2
      all_values_recalculated(user).should == result_values
    end
  end

  describe "::queue_recalculate_for_user", delay_jobs: false do

    before(:each) do
      Rails.configuration.stub(:recalculate_member_value_after_action).and_return(true)
      @page_override = create(:page_with_parent, member_value_type: other_type.to_s)
    end

    context "default member value type" do
      it "should recalculate the member value type for external actions" do
        page = create(:page_with_parent)
        assert_value_type_recalculated
        MemberValue.queue_recalculate_for_user(user, :external_action, create(value_type_content_module), page, nil)
      end
    end

    context "action taken" do
      it "should recalculate the member value type based on the page override" do
        assert_value_type_recalculated(other_type)
        MemberValue.queue_recalculate_for_user(user, :action_taken, create(value_type_content_module), @page_override, nil)
      end
    end

    context "external action" do
      it "should recalculate the member value type based on the page override" do
        assert_value_type_recalculated(other_type)
        MemberValue.queue_recalculate_for_user(user, :external_action, create(value_type_content_module), @page_override, nil)
      end
    end
  end

  def assert_value_type_recalculated(type=@value_type)
    if type == :time
      MemberValue.should_not_receive(:recalculate_money_value)
      MemberValue.should_receive(:recalculate_time_value)
      MemberValue.should_not_receive(:recalculate_voice_value)
    else
      MemberValue.should_not_receive(:recalculate_money_value)
      MemberValue.should_not_receive(:recalculate_time_value)
      MemberValue.should_receive(:recalculate_voice_value)
    end
  end
  
  def action_type
    actions = {voice: :petition_action, time: :call_mp_action}
    actions[@value_type]
  end

  def other_type
    @value_type == :voice ? :time : :voice
  end

  def value_type_content_module
    actions = {voice: :petition_module, time: :call_mp_module}
    actions[@value_type]
  end
end
