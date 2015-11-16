module InterruptableJob

  INTERRUPTED_QUEUE = 'interrupted'

  CANCEL_STATUS = {
      interrupted: 'interrupted',
      destroyed: 'destroyed'
  }

  attr_reader :job

  def before(job)
    @job = job
  end

  def interrupted?
    @job.reload
    @job.queue == INTERRUPTED_QUEUE
  end

  def self.cancel(job_id)
    if acquire_lock(job_id)
      destroy(job_id)
      CANCEL_STATUS[:destroyed]
    else
      interrupt(job_id)
      CANCEL_STATUS[:interrupted]
    end
  end

  def self.acquire_lock(job_id)
    Delayed::Job.update_all(['locked_at = ?, locked_by = ?', Time.now.utc, 'InterruptableJob'], "id = #{job_id} AND locked_at IS NULL") == 1
  end

  def self.destroy(job_id)
    job = Delayed::Job.where(id: job_id, locked_by: 'InterruptableJob').first
    raise "Unable to destroy job #{job_id}: it has not been locked" unless job
    job.destroy
  end

  def self.interrupt(job_id)
    Delayed::Job.where(id: job_id).first.update_attribute(:queue, INTERRUPTED_QUEUE)
  end

  def self.interrupted?(job_id)
    Delayed::Job.where(id: job_id, queue: INTERRUPTED_QUEUE).count > 0
  end


end
