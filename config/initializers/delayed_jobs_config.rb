# config/initializers/delayed_job_config.rb
Delayed::Worker.backend = :active_record
Delayed::Worker.destroy_failed_jobs = false
Delayed::Worker.sleep_delay = 3
#Delayed::Worker.max_attempts = 3
Delayed::Worker.max_run_time = 4.hours
Delayed::Worker.delay_jobs = true

# Optional but recommended for less future surprises.
# Fail at startup if method does not exist instead of later in a background job 
[[ExceptionNotifier, :notify_exception]].each do |object, method_name|
  raise NoMethodError, "undefined method `#{method_name}' for #{object.inspect}" unless object.respond_to?(method_name, true)
end

# Chain delayed job's handle_failed_job method to do exception notification
Delayed::Worker.class_eval do

  def handle_failed_job_with_notification(job, error)
    handle_failed_job_without_notification(job, error)
    ExceptionNotifier.notify_exception(error, data: {job: (job || {}).to_yaml, server: (`hostname` || 'unknown')})
  end
  alias_method_chain :handle_failed_job, :notification
end


