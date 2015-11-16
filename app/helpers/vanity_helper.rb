module VanityHelper
  SESSION_KEY_EXPERIMENTS = :vanity_experiment_experiment_ids
  def track_experiment_in_session(name)
    experiment_ids = session[SESSION_KEY_EXPERIMENTS] || []
    unless experiment_ids.include?(name)
      experiment_ids << name
      session[SESSION_KEY_EXPERIMENTS] = experiment_ids
    end
  end

  def experiment_id(experiment)
    if experiment.respond_to?(:experiment_id)
      experiment.experiment_id
    else
      experiment.name
    end
  end

  def track_with_user(metric, amount, tracked_user, associated_object, identity = nil, experiment_numeric_ids=nil)
    identity ||= identity_from_cookie
    Vanity.track! metric, { values: [amount], identity: identity }
    update_participant_with_user_id tracked_user, identity
    record_conversion metric, amount, tracked_user, identity, associated_object, experiment_numeric_ids
  end

  def ab_test(name)
    Vanity.context.track_experiment_in_session(name)
    super(name)
  end

  def update_participant_with_user_id(tracked_user=nil, identity=nil)
    tracked_user ||= TrackingTokenLookup.new(params['t']).user
    identity ||= identity_from_cookie
    if identity && tracked_user
      Vanity::Adapters::ActiveRecordAdapter::VanityParticipant
        .where(identity: identity)
        .update_all(user_id: tracked_user.id)
    end
  end

  protected

  def record_conversion(metric, amount, tracked_user, identity, associated_object, experiment_numeric_ids)
    if identity && tracked_user
      experiments = experiment_experiment_ids(experiment_numeric_ids)
      return unless experiments
      Vanity::Adapters::ActiveRecordAdapter::VanityParticipant.where(identity: identity, experiment_id: [experiments]).each do |participant|
        experiment = Vanity.playground.experiments[participant.experiment_id.to_sym]
        next unless experiment && experiment.enabled? 
        alternative_name = experiment.alternatives[participant.seen].value
        VanityParticipantConversion.create!({
          participant_id: participant.id,
          user_id: participant.user_id,
          metric: metric,
          value: amount,
          experiment_id: participant.experiment_id,
          alternative: alternative_name,
          additional_id: associated_object.try(:id)
        })
      end
    end
  end

  def experiment_experiment_ids(experiment_numeric_ids)
    ids = experiment_ids_list(experiment_numeric_ids) 
    if ids
      return ids
    else 
      return session[SESSION_KEY_EXPERIMENTS] if defined?(session)
    end
    return nil
  end

  def experiment_ids_list(numeric_str)
    return nil unless numeric_str
    numeric_ids = numeric_str.split(',')
    Vanity::Adapters::ActiveRecordAdapter::VanityExperiment.where(id: numeric_ids).map{|exp| exp.experiment_id }
  end

  def identity_from_cookie
    cookies['vanity_id_v3'] if defined?(:cookies)
  end

  def experiment_numeric_ids_in_session
    (session[SESSION_KEY_EXPERIMENTS] || []).map {|experiment| Vanity::Adapters::ActiveRecordAdapter::VanityExperiment.find_by_experiment_id(experiment).try(:id) }.collect{|e| e }.join(',')
  end

end
