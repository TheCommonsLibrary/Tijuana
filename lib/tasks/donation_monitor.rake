# add bootstrap the donation monitor to jobs:work
namespace :jobs do
  task :work => :start_monitor

  task :start_monitor do
    PeriodicDonationMonitorJob.bootstrap
  end
end
