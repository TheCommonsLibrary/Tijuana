require File.expand_path(File.dirname(__FILE__) + "../../spec_helper")

describe PeriodicDonationMonitorJob do

  describe "PeriodicDonationMonitorJob.bootstrap" do
    it "should queue a monitor job to run immediately" do
      Timecop.freeze do
        PeriodicDonationMonitorJob.bootstrap
        job = Delayed::Job.first
        job.run_at.utc.to_s.should == Time.now.utc.to_s
      end
    end
    it "should not queue another monitor job if one already exists" do
      PeriodicDonationMonitorJob.bootstrap
      PeriodicDonationMonitorJob.bootstrap
      Delayed::Job.count.should == 1
    end
  end

  describe "after" do
    it "should queue a new PeriodicDonationMonitorJob to run later (1 hour?)" do
      subject.after
      Delayed::Job.count.should == 1
      Delayed::Job.last.run_at >= Time.now + 59.minutes
    end

    it "should not queue more than 2 PeriodicDonationMonitorJobs (1 running (ending), one to run next time" do
      subject.after
      subject.after
      Delayed::Job.count.should == 2
      subject.after
      Delayed::Job.count.should == 2
    end
  end

  describe "perform" do
    it "checks has_periodic_donations_overdue and should not send warning email if false" do
      Donation.should_receive(:some_of_the_periodic_donations_overdue_by).with(2.hours).and_return([])
      TechMailer.should_not_receive(:donation_monitor_warning_email)
      subject.perform
    end
    it "checks periodic_donations_overdue and should send warning email if any" do
      overdue_donations = [double(Donation)]
      Donation.should_receive(:some_of_the_periodic_donations_overdue_by).with(2.hours).and_return(overdue_donations)
      mock_mail = double("mail")
      TechMailer.should_receive(:donation_monitor_warning_email).with(overdue_donations, "2 hours").and_return(mock_mail)
      mock_mail.should_receive(:deliver)
      subject.perform
    end
  end

end
