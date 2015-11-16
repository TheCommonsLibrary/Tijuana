module WorkOffHelper
  def wait_for_job
    timeout = 5
    while timeout > 0
      return if Delayed::Job.where('run_at <= ?', Time.now + 5.seconds).count > 0
      sleep 0.1
      timeout -= 0.1
    end
  end
  
  def work_off
    wait_for_job
    Delayed::Worker.new.work_off until Delayed::Job.where('run_at <= ?', Time.now + 5.seconds).count == 0
  end
  
  def work_off_new_mail
    reset_mailer
    work_off
  end
end
RSpec.configuration.include WorkOffHelper
