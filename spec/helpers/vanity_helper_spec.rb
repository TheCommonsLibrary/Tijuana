require 'spec_helper'

describe VanityHelper do
  include VanityTestHelper

  describe "#track_experiment_in_session" do
    let!(:experiment){ new_ab_test :price_options }

    it "should record the experiment in the session" do
      helper.track_experiment_in_session(experiment.name)
      helper.request.session[VanityHelper::SESSION_KEY_EXPERIMENTS].should == [:price_options]
    end

    it "should record the same experiment once" do
      helper.track_experiment_in_session(experiment.name)
      helper.track_experiment_in_session(experiment.name)
      helper.request.session[VanityHelper::SESSION_KEY_EXPERIMENTS].should == [:price_options]
    end
  end

  describe "track_with_user" do
    let!(:user) { create(:user) }
    let(:cookie_string) { "random_cookie_string" }
    let(:amount_in_cents) { 200 }
    let(:donation){ create(:donation) }
    let(:alternative){ 1 }
    let!(:experiment){ new_ab_test :price_options }

    before do
      helper.request.cookies["vanity_id_v3"] = cookie_string
      register_participant('price_options', cookie_string, alternative)
    end

    it "track_with_user sets the user_id on the participant record" do
      helper.track_with_user(:money, amount_in_cents, user, donation)
      vanity_participant_model.where(user_id: user.id).count.should == 1
    end

    it "records an entry for the conversion" do
      session[VanityHelper::SESSION_KEY_EXPERIMENTS] = [:price_options]
      helper.track_with_user(:money, amount_in_cents, user, donation)
      conversions = VanityParticipantConversion.where(user_id: user.id)
      conversions.count.should == 1
      conversion = conversions.first
      conversion.experiment_id.should == 'price_options'
      conversion.alternative.should == 'second'
      conversion.metric.should == 'money'
      conversion.value.should == amount_in_cents
      conversion.additional_id.should == donation.id
    end

    context "with an experiment that has completed" do
      it "should not record an entry for the conversion" do
        experiment.complete!(:second)
        helper.track_with_user(:money, amount_in_cents, user, donation)
        expect(VanityParticipantConversion.where(user_id: user.id).count).to be_zero
      end
    end

    context "with a participant enrolled in multiple experiments" do
      let!(:session_experiment) { new_ab_test :sessions }

      before do
        register_participant('sessions', cookie_string, alternative)
        helper.request.cookies["vanity_id_v3"] = cookie_string
      end

      it "should only record a conversion for experiment in current session" do
        session[VanityHelper::SESSION_KEY_EXPERIMENTS] = [session_experiment.id]
        helper.track_with_user(:money, amount_in_cents, user, donation)
        expect(VanityParticipantConversion.where(user_id: user.id).count).to eq 1
      end

      it "should conversions for multiple experiment in current session" do
        session[VanityHelper::SESSION_KEY_EXPERIMENTS] = ['sessions', 'price_options']
        helper.track_with_user(:money, amount_in_cents, user, donation)
        expect(VanityParticipantConversion.where(user_id: user.id, experiment_id: 'sessions').count).to eq 1
        expect(VanityParticipantConversion.where(user_id: user.id, experiment_id: 'price_options').count).to eq 1
      end
    end
  end

  describe "#experiment_numeric_ids_in_session" do
    before { session[VanityHelper::SESSION_KEY_EXPERIMENTS] = nil }
    specify {helper.experiment_numeric_ids_in_session.should == '' }
    
    context "with experiments" do
      let!(:sign_with_fb) {new_ab_test :sign_with_fb}
      before { session[VanityHelper::SESSION_KEY_EXPERIMENTS] = [:sign_with_fb]}
      specify {helper.experiment_numeric_ids_in_session.should == "#{Vanity::Adapters::ActiveRecordAdapter::VanityExperiment.first.id}" }
    end

    context "with unknown experiment" do
      before { session[VanityHelper::SESSION_KEY_EXPERIMENTS] = [:foo_experiment]}
      specify {helper.experiment_numeric_ids_in_session.should == '' }
    end

    context "with multiple experiments" do
      let!(:sign_with_fb) {new_ab_test :sign_with_fb}
      let!(:user_detection) {new_ab_test :user_detection}
      before { session[VanityHelper::SESSION_KEY_EXPERIMENTS] = [:sign_with_fb, :user_detection]}
      it "should produce a comma separated list of numeric experiment ids" do
        ids = helper.experiment_numeric_ids_in_session.split(",").map(&:to_i)
        experiment_ids = [Vanity::Adapters::ActiveRecordAdapter::VanityExperiment.find_by_experiment_id('sign_with_fb').id, Vanity::Adapters::ActiveRecordAdapter::VanityExperiment.find_by_experiment_id('user_detection').id]
        expect(ids).to match_array(experiment_ids)
      end
    end
  end
end
