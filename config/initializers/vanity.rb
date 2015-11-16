Vanity.configure do |config|
  config.use_js = true
  config.cookie_name = 'vanity_id_v3'
end

#redef ab_test to ensure experiments are tracked in session
module Vanity::Helpers

  def ab_test_with_session_tracking(name, current_request=nil)
    Vanity.context.track_experiment_in_session(name)
    ab_test_without_session_tracking(name, current_request)
  end

  alias_method_chain :ab_test, :session_tracking
end

