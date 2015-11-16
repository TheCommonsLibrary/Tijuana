module VanityTestHelper
  class FakeContext
    def vanity_store_experiment_for_js(name, alternative)
      @_vanity_experiments ||= {}
      @_vanity_experiments[name] ||= alternative
      @_vanity_experiments[name].value
    end

    def track_experiment_in_session(exp_name)
      @_vanity_session ||= {}
      experiment_ids = @_vanity_session[VanityHelper::SESSION_KEY_EXPERIMENTS] || []
      unless experiment_ids.include?(exp_name)
        experiment_ids << exp_name
      @_vanity_session[VanityHelper::SESSION_KEY_EXPERIMENTS] = experiment_ids
      end
    end
    
  end

  def vanity_participant_model
    Vanity::Adapters::ActiveRecordAdapter::VanityParticipant
  end

  def register_participant(experiment, identity, alternative)
    vanity_participant_model.create!(identity: identity, experiment_id: experiment, seen: alternative)
  end

  def new_ab_test(name)
    id = name.to_s.downcase.gsub(/\W/, "_").to_sym
    experiment = Vanity::Experiment::AbTest.new(Vanity.playground, id, name)
    experiment.instance_eval do
      metrics :money
      alternatives :first,:second
      default :second
    end
    experiment.enabled = true
    experiment.save
    Vanity.playground.experiments[id] = experiment
    experiment
  end

  def setup_fake_context
    Vanity.context = FakeContext.new
  end

  def experiment_numeric_id(experiment)
    Vanity::Adapters::ActiveRecordAdapter::VanityExperiment.find_by_experiment_id(experiment.id).id
  end

end
