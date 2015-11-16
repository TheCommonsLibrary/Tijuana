desc "check that the workers are up (meant to be run from cron every 30 mins)"
task :worker_check => :environment do
  worker_count = `ps aux | grep 'ruby' | grep 'rake jobs:work' | grep -v 'sh -c' | wc -l`.strip.to_i
  exit 0 if worker_count > 1 # workers are running, finish quietly

  query = """
    SELECT id
    FROM delayed_jobs
    WHERE (run_at < ? AND failed_at is NULL)
  """
  job_count = ActiveRecord::Base.execute_escaped(query, Time.now).count

  # abort sends to STDERR, so we get emailed
  abort """
    There are only #{worker_count} worker(s) running on #{`hostname`}
    and there are #{job_count} job(s) waiting to be processed.

    Please rectify the situation by running `rake cloud:enlist` from your
    servers directory with the appropriate NAME, ENVIRONMENT, and ZONE vars.
  """
end
