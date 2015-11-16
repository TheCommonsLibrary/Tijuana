require 'spec_helper'
require_relative 'member_value_behaviour.rb'
require_relative 'monovalue_member_value_type_behaviour.rb'

describe MemberValue do
  it_behaves_like 'member value', :voice
  it_behaves_like 'member value', :time
  it_behaves_like 'member value', :money
  it_behaves_like 'monovalue type', :voice
  it_behaves_like 'monovalue type', :time

  let(:user) { create(:user) }

  specify { MemberValue.current_values_for_user(user).should be_empty }

  describe "voice value" do

    describe "default page value types are preserved" do
      it "should record member value as the default value type" do
        [:petition_module, :email_targets_module, :email_mp_module, :target_list_module].each do |content_module| 
          create(:action_taken_activity, content_module: create(content_module), user: user)
        end

        voice_value(user).should == {voice: 4, time: 0, money: 0}
      end

      it "should record member value for external actions" do
        [:petition_module, :email_targets_module, :email_mp_module, :target_list_module].each do |content_module| 
          create(:action_taken_activity, content_module: create(content_module), user: user, activity: 'external_action')
        end

        voice_value(user).should == {voice: 4, time: 0, money: 0}
      end
    end
  end

  describe "time value" do
    describe "default page value types are preserved" do

      it "should record time actions as time member value" do
        create(:action_taken_activity, content_module: create(:call_mp_module), user: user)
        all_values_recalculated(user).should == {voice: 0, time: 1, money: 0}
        create(:attend_event_action, user: user)
        all_values_recalculated(user).should == {voice: 0, time: 2, money: 0}
      end

      it "should record member value for external actions" do
        create(:action_taken_activity, content_module: create(:call_mp_module), user: user, activity: 'external_action')
        all_values_recalculated(user).should == {voice: 0, time: 1, money: 0}
      end

      it "should record member value attributes correctly" do
        page = create(:page_with_parent)
        create(:action_taken_activity, content_module: create(:call_mp_module), page: page, campaign: page.page_sequence.campaign, user: user)
        all_values_recalculated(user)

        MemberValue.count.should == 1
        member_value = MemberValue.first
        member_value.user.id.should == user.id
        member_value.campaign_id.should == page.page_sequence.campaign.id
        member_value.page_id.should == page.id
        member_value.current.should == true
        member_value.value_type.should == :time
        member_value.cumulative_value.should == 1
        member_value.delta_value.should == 1
      end

      #e.g. get togethers do not set campaign
      it "should record campaign from the event when the UAE doesn't have a campaign" do
        campaign = create(:campaign)
        get_together = create(:get_together, campaign: campaign)
        action = create(:attend_event_action_without_campaign, get_together_event_id: create(:event, get_together: get_together).id, user: user)

        all_values_recalculated(user)
        member_value = MemberValue.first
        member_value.campaign_id.should == campaign.id
      end
    end

    describe "::queue_recalculate_for_user", delay_jobs: false do

      it "should recalculate time member value for events" do
        Rails.configuration.stub(:recalculate_member_value_after_action).and_return(true)
        page = create(:page_with_parent)
        MemberValue.should_not_receive(:recalculate_money_value)
        MemberValue.should_receive(:recalculate_time_value)
        MemberValue.should_not_receive(:recalculate_voice_value)

        MemberValue.queue_recalculate_for_user(@user, :action_taken, nil, page, create(:event))
      end
    end
  end

  describe "money value" do
    it "should not allow page to override the value type" do
      voice_page = create(:page_with_parent, member_value_type: 'voice')
      create(:donation_action, user: user, page: voice_page)
      donation = create(:donation, user: user, page: voice_page, amount_in_cents: 1000)
      create(:transaction, donation: donation, amount_in_cents: 1000)

      all_values_recalculated(user).should == {voice: 0, time: 0, money: 1000}

      time_page = create(:page_with_parent, member_value_type: 'time')
      create(:donation_action, user: user, page: time_page)
      donation = create(:donation, user: user, page: time_page, amount_in_cents: 500)
      create(:transaction, donation: donation, amount_in_cents: 500)

      all_values_recalculated(user).should == {voice: 0, time: 0, money: 1500}
    end

    it "should ignore refunds and unsuccessful transactions" do
      user = create(:user)
      donation = create(:donation, user: user)
      create(:transaction, donation: donation, successful: false)
      refunded = create(:transaction, donation: donation, refunded: true)
      create(:transaction, donation: donation, refund_of_id: refunded.id)

      all_values_recalculated(user).should be_empty
    end
  end

  def current_value(user)
    MemberValue.current_values_for_user(user)
  end

  def recalculate_money(user)
    MemberValue.recalculate_money_value(user)
  end

  def recalculate_time(user)
    MemberValue.recalculate_time_value(user)
  end

  def recalculate_voice(user)
    MemberValue.recalculate_voice_value(user)
  end

  def all_values_recalculated(user)
    MemberValue.recalculate_voice_value(user)
    MemberValue.recalculate_time_value(user)
    MemberValue.recalculate_money_value(user)
    current_value(user)
  end

  def voice_value(user)
    recalculate_voice(user)
    current_value(user)
  end

  def time_value(user)
    recalculate_time(user)
    current_value(user)
  end

 describe "VOICE_MODULES" do
    module ModuleModule; end
    class UnrelatedModule; end
    class NotVoiceModule
      def member_value_voice_module?; false; end
    end
    class VoiceModule
      def member_value_voice_module?; true; end
    end

    let(:modules) { MemberValue.voice_modules }

    # these first two would error anyway; this documents the intent
    it "does not include actual ruby modules" do
      expect(modules).to_not include("ModuleModule")
    end

    it "does not include classes that are unrelated" do
      expect(modules).to_not include("UnrelatedModule")
    end

    it "does not include classes that are not voice modules" do
      expect(modules).to_not include("NotVoiceModule")
    end

    it "includes module classes that are voice modules" do
      expect(modules).to include("VoiceModule")
    end
  end

end
