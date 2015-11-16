class Blast < ActiveRecord::Base
  acts_as_paranoid
  acts_as_user_stampable
  belongs_to :push
  has_many :emails
  has_one :list

  validates :name, :length => { :maximum => 64, :minimum => 3 }

  def proofed_emails
    emails.proofed_emails
  end

  def send_all_proofed_emails!(limit=nil)
    enqueue_job_and_update_blast_with_job_id(limit)
  end

  def send_proofed_emails!(email_ids, limit=nil)
    enqueue_job_and_update_blast_with_job_id(limit, proofed_emails.find(email_ids))
  end

  def enqueue_job_and_update_blast_with_job_id(limit, emails=nil)
    log("Starting enqueue_job_and_update_blast_with_job_id")
    self.push.create_activities_table
    emails ||= proofed_emails.all
    run_at = Time.now + AppConstants.blast_job_delay
    job_handle = self.delay(:run_at => run_at).segment_user_ids_per_job(emails, limit)
    log("Created segment_user_ids_per_job job")
    self.update_attribute(:delayed_job_id, job_handle.id)
  end
  private :enqueue_job_and_update_blast_with_job_id

  def segment_user_ids_per_job(emails_to_send, limit)
    log("Starting segment_user_ids_per_job job")
    self.update_attribute(:delayed_job_id, nil)
    no_jobs = emails_to_send.size
    current_job_id = 0
    Email.update_all('cut_completed_at = NULL', ['blast_id = ?', emails_to_send[0].blast_id])
    emails_to_send.each do |email|
      enqueue_job(current_job_id, email, limit, no_jobs)
      current_job_id += 1
      log("Enqueued job for email##{email.id}")
    end
    log("Finished segment_user_ids_per_job job")
  end
  private :segment_user_ids_per_job

  def log(msg)
    Rails.logger.info("BLAST_DEBUG Blast##{self.id}: " + msg)
  end
  private :log

  def enqueue_job(current_job_id, email, limit, no_jobs)
    blast_job = BlastJob.new({
                                 :no_jobs => no_jobs,
                                 :current_job_id => current_job_id,
                                 :list => list,
                                 :email => email,
                                 :limit => limit
                             })
    delay = !Rails.env.test? ? 0 : 5.seconds
    job_handle = Delayed::Job.enqueue(blast_job, {:run_at => Time.now + delay})
    email.update_attribute(:delayed_job_id, job_handle.id)
  end

  def has_pending_jobs?
    (!self.delayed_job_id.nil?) ||
        (proofed_emails.where("delayed_job_id IS NOT NULL").count != 0)
  end

#NOTE: does not cancel running jobs
  def cancel
    Delayed::Job.where(:id => self.delayed_job_id, :locked_at=>nil).destroy_all
    self.update_attribute(:delayed_job_id, nil)
  end

  def remaining_time_for_existing_jobs
    job_ids = [self.delayed_job_id]
    jobs = Delayed::Job.where(:id => job_ids).order("run_at desc").limit(1)
    job = jobs.first
    return 0 unless job
    seconds = job.run_at - Time.now
    seconds < 0 ? 0 : (seconds * 100).round.to_f / 100
  end

  def in_cooling_off_period?
    self.delayed_job_id
  end
end
