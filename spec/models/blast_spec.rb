require File.expand_path(File.dirname(__FILE__) + "../../spec_helper")

describe Blast do
  describe "validations" do
    it "should require a name between 3 and 64 characters" do
      Blast.new(:name => "Save the kittens!").should be_valid
      Blast.new(:name => "AB").should_not be_valid
      Blast.new(:name => "X" * 64).should be_valid
      Blast.new(:name => "Y" * 65).should_not be_valid
    end
  end

  describe "checks" do
    it "should return a list of proofed emails" do
      user_ids = [33,55,66]

      list = List.create!

      blast = create(:blast, :name => "Fight like a mongoose!", :list => list)
      email = create(:proofed_email, :body => "Proofed", :blast => blast)
      other_email = create(:email, :blast=>blast)

      blast.proofed_emails.should == [email]
    end

    it "should say whether there are pending jobs" do
      list = List.create!

      blast = create(:blast, :name => "Fight like a mongoose!", :list => list)
      email = create(:proofed_email, :body => "Proofed", :blast => blast, :delayed_job_id => 10)

      blast.has_pending_jobs?.should be true

      email.delayed_job_id = nil
      email.save

      blast.has_pending_jobs?.should be false

      blast1 = create(:blast, :name => "Fight like a mongoose!", :list => list, :delayed_job_id => 9)
      blast1.has_pending_jobs?.should be true
      blast1.update_attribute(:delayed_job_id, nil)
      blast1.has_pending_jobs?.should be false
    end
  end
  
  describe "delivery" do
    before(:each) do
      Push.any_instance.stub(:create_activities_table)
    end

    context "blast with multiple emails" do
      let(:push) { create(:push) }
      let(:list) { List.create! }
      let(:blast_with_multiple_emails) { Blast.create!(:name => "Save the walruses!", :list => list, :push => push) }
      let(:proofed_emails) {
        5.times.inject([]) do |acc, index|
          email = create(:proofed_email, :blast => blast_with_multiple_emails)
          acc << email
          acc
        end
      }
      it "should assign the job id to the blast in order to provide a way to cancel it" do
        email = proofed_emails[0]
        email.delayed_job_id.should be_nil
        blast_with_multiple_emails.delayed_job_id.should be_nil
        BlastJob.should_receive(:new).with(hash_including(:no_jobs => 1, :current_job_id => 0, :list => list, :email => email, :limit => nil)).and_return(double(:perform=>true))

        blast_with_multiple_emails.send_proofed_emails!([email.id])

        blast_with_multiple_emails.delayed_job_id.should_not be_nil
        Delayed::Worker.new.work_off
        email.reload.delayed_job_id.should_not be_nil
        email.cut_completed_at.should == nil
        blast_with_multiple_emails.reload
        blast_with_multiple_emails.delayed_job_id.should be_nil
      end

      it "should create five blast jobs, one per email" do
        proofed_emails.each_with_index do |email, index|
          BlastJob.should_receive(:new).with(hash_including(:no_jobs => proofed_emails.size, :current_job_id => index, :list => list, :email => email, :limit => nil)).and_return(double(:perform=>true))
        end

        blast_with_multiple_emails.send_all_proofed_emails!
        Delayed::Worker.new.work_off
      end

      it "should create blast jobs for the given emails only" do
        BlastJob.should_receive(:new).with(hash_including(:no_jobs => 2, :current_job_id => 0, :list => list, :email => proofed_emails[0], :limit => nil)).and_return(double(:perform=>true))
        BlastJob.should_receive(:new).with(hash_including(:no_jobs => 2, :current_job_id => 1, :list => list, :email => proofed_emails[1], :limit => nil)).and_return(double(:perform=>true))

        blast_with_multiple_emails.send_proofed_emails!([proofed_emails[0].id, proofed_emails[1].id])
        proofed_emails[0].cut_completed_at.should == nil
        proofed_emails[1].cut_completed_at.should == nil
        Delayed::Worker.new.work_off
      end

      it "should pass the limit down to given emails" do
        BlastJob.should_receive(:new).with(hash_including(:no_jobs => 2, :current_job_id => 0, :list => list, :email => proofed_emails[0], :limit => 500)).and_return(double(:perform=>true))
        BlastJob.should_receive(:new).with(hash_including(:no_jobs => 2, :current_job_id => 1, :list => list, :email => proofed_emails[1], :limit => 500)).and_return(double(:perform=>true))

        blast_with_multiple_emails.send_proofed_emails!([proofed_emails[0].id, proofed_emails[1].id], 500)
        Delayed::Worker.new.work_off
      end
    end

    context "blast with a single email" do
      let(:push) { create(:push) }
      let(:list) { List.create! }
      let(:blast_with_single_email) { Blast.create!(:name => "Save the walruses!", :list => list, :push => push) }
      let(:proofed_email) do 
        email = create(:email, :test_sent_at => Time.now, :blast => blast_with_single_email)
        email.send_test!(['dummy@email.com'])
        email
      end

      it "should create a single blast job when sending a single email" do
        BlastJob.should_receive(:new).with(hash_including(:no_jobs => 1, :current_job_id => 0, :list => list, :email => proofed_email, :limit => nil)).and_return(double(:perform=>true))

        blast_with_single_email.send_all_proofed_emails!
        proofed_email.cut_completed_at.should == nil
        Delayed::Worker.new.work_off
      end

      it "should pass the limit down to each job" do
        BlastJob.should_receive(:new).with(hash_including(:no_jobs => 1, :current_job_id => 0, :list => list, :email => proofed_email, :limit => 500)).and_return(double(:perform=>true))

        blast_with_single_email.send_all_proofed_emails!(500)
        Delayed::Worker.new.work_off
      end
    end

    it "should cancel the delivery of any pending, non-locked jobs" do
      list = List.create!
      blast = Blast.create!(:name => "Save the walruses!", :list => list, :delayed_job_id => 17)

      job_double = double()
      job_double.should_receive(:destroy_all)
      Delayed::Job.should_receive(:where) do |hash|
        hash[:id].should eql 17
        hash[:locked_at].should be_nil
        job_double
      end

      blast.cancel

      blast.reload
      blast.delayed_job_id.should be_nil
    end
  end

  describe "#in_cooling_off_period?" do
    specify {subject.delayed_job_id.should eql subject.in_cooling_off_period?}
  end

  describe "#remaining_time_for_existing_jobs" do
    it "should return the remaining time in seconds for any pending jobs" do
      class DelayedJob < ActiveRecord::Base; end
      job = DelayedJob.create(:run_at => 5.minutes.from_now)
      blast = Blast.create!(:name => "Save the walruses!", :delayed_job_id => job.id)

      blast.remaining_time_for_existing_jobs.should > 0
    end

    it "should return zero if negative result" do
      class DelayedJob < ActiveRecord::Base; end
      job = DelayedJob.create(:run_at => 1.minute.ago)
      blast = create(:blast, :name => "Save the walruses!")
      create(:proofed_email, :delayed_job_id => job.id, :blast => blast)

      blast.remaining_time_for_existing_jobs.should == 0
    end

    it "should return 0 when there are no pending jobs" do
      blast = create(:blast, :name => "Save the walruses!")
      create(:proofed_email, :blast => blast)

      blast.remaining_time_for_existing_jobs.should == 0
    end
  end

end
