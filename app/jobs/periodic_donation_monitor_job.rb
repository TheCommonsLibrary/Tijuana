class PeriodicDonationMonitorJob

  QUEUE = 'PeriodicDonationMonitorJobSingleton'

  def perform
    Rails.logger.info {"PeriodicDonationCheckerJob#perform"}
    overdue_donations = Donation.some_of_the_periodic_donations_overdue_by 2.hours
    if overdue_donations.present?
      TechMailer.donation_monitor_warning_email(overdue_donations, '2 hours').deliver
    end
  end

  def after
    if PeriodicDonationMonitorJob.number_of_jobs_in_queue <= 1
      PeriodicDonationMonitorJob.run_me_at Time.now + 1.hour
    end
  end

  def self.bootstrap
    Rails.logger.info {"PeriodicDonationCheckerJob.bootstrap"}
    if number_of_jobs_in_queue == 0
      run_me_at Time.now
    else
      Rails.logger.info {"PeriodicDonationCheckerJob already exists"}
    end
  end

  private

  def self.run_me_at run_at
    Rails.logger.info {"PeriodicDonationCheckerJob queuing new job to run at #{run_at}"}
    Delayed::Job.enqueue(PeriodicDonationMonitorJob.new , {:run_at => run_at, :queue => QUEUE })
  end

  def self.number_of_jobs_in_queue
    Delayed::Job.where(:queue => QUEUE).count
  end

end
