class BlastJob
  attr_reader :options, :email, :list
  def initialize(options)
    @options = options
    @email = options.delete(:email)
    @list = options.delete(:list)
  end

  def perform
    log("Starting job")
    user_ids = list.filter_by_rules_excluding_users_from_push(email.blast.push, options)
    log("Collected #{user_ids.count} user ids")
    email.update_attribute(:cut_completed_at, Time.zone.now)
    synchronise_blasts if @options[:no_jobs] > 1
    log("All list cuts complete. Proceeding to blast.")
    email.deliver_blast_in_batches(user_ids)
    log("Emails all delivered")
    email.blast.update_attribute(:sent_at, Time.zone.now)
    log("Job completed successfully")
    log_sent_email(user_ids)
  rescue Exception => e
    email.blast.update_attribute(:sent_at, nil)
    PushLog.log_exception(email, "N/A", e)
    log("EXCEPTION: #{e}")
    ExceptionNotifier.notify_exception(e)
  ensure
    email.update_attribute(:delayed_job_id, nil)
    email.blast.push.release_lock if last_job_in_blast?(email)
  end

  def log_sent_email(user_ids)
    SentEmail.create!(email: email, subject: email.subject, body: email.body, recipient_count: user_ids.count, sql: list.get_sql_query_string_for_dashboard_user)
  rescue Exception => e
    log("EXCEPTION: #{e}")
    ExceptionNotifier.notify_exception(e)
  end

  private

  def synchronise_blasts
    start = Time.now
    while Time.now < start + 600.seconds do
      if all_blasts_cut?(email)
        log("Detected completion of blast cuts.")
        break
      end
      sleep(1)
    end
  end

  def all_blasts_cut?(email)
    email.blast.proofed_emails.where("cut_completed_at IS NOT NULL").count == @options[:no_jobs]
  end

  def last_job_in_blast?(email)
    email.blast.proofed_emails.where("delayed_job_id IS NOT NULL").count == 0
  end

  def log(msg)
    Rails.logger.info("BLAST_DEBUG Email##{email.id} BlastJob: " + msg)
  end
end

