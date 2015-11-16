module ActionDispatch::Http::FilterParameters

  protected

  # see Exclude rack.request.form_vars from request.filtered_env https://github.com/rails/rails/pull/3305
  # this was merged into rails but appears to have been lost
  def env_filter
    parameter_filter_for(Array.wrap(@env["action_dispatch.parameter_filter"]) + [/RAW_POST_DATA/, "rack.request.form_vars"])
  end

end