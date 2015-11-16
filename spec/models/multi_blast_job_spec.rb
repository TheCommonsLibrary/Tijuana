require File.expand_path(File.dirname(__FILE__) + "../../spec_helper")

describe MultiBlastJob do

  let(:push) { create(:push) }
  let(:email1) { create(:proofed_email, name: 'email1', blast: create(:blast, push: push, list: create(:list))) }

  describe "perform" do
    without_transactional_fixtures do

      let(:email2) { create(:email, blast: email1.blast) }

      let(:job) { MultiBlastJob.new(email_ids: [email1.id, email2.id]) }

      it "should perform BlastJob for each email" do
        blast_job1 = double(BlastJob)
        blast_job2 = double(BlastJob)

        BlastJob.should_receive(:new).with(
            hash_including(
                no_jobs: 1, #only one job runs concurrently
                list: email1.blast.list, #list for email
                email: email1, #the email
                limit: nil #send to all (unsent) members of list
            )
        ).ordered.and_return(blast_job1)
        blast_job1.should_receive(:perform).ordered

        BlastJob.should_receive(:new).with(
            hash_including(
                no_jobs: 1, #only one job runs concurrently
                list: email2.blast.list, #list for email
                email: email2, #the email
                limit: nil #send to all (unsent) member of list
            )
        ).ordered.and_return(blast_job2)
        blast_job2.should_receive(:perform).ordered


        simulate_worker(job)
      end

      it "resets blast job ids as BlastJobs are performed" do
        simulate_worker(job)
        email1.blast.delayed_job_id.should be_nil
        email2.blast.delayed_job_id.should be_nil
      end
    end
  end

  describe "valid?" do

    it "should be valid" do
      email2 = create(:proofed_email, blast: create(:blast, push: push, list: create(:list)))
      job = MultiBlastJob.new(email_ids: [email2.id, email1.id], push: push)
      job.should be_valid
    end

    it "validate email ids has at least two ids" do
      job = MultiBlastJob.new(email_ids: [email1.id], push: push)
      job.should_not be_valid
      job.errors[:multi_blast].should == ["requires at least two ids"]
    end

    it "validate email exists" do
      job = MultiBlastJob.new(email_ids: [email1.id, -1], push: push)
      job.should_not be_valid
      job.errors[:email].should == ["-1 does not exist"]
    end

    it "validate only 1 email per blast" do
      email2 = create(:proofed_email, name: 'email2', blast: email1.blast)
      job = MultiBlastJob.new(email_ids: [email1.id, email2.id], push: push)
      job.should_not be_valid
      job.errors[:emails].should == ["'#{email1.name}' and '#{email2.name}' are in the same blast"]
    end

    it "validate emails are in same push" do
      email2 = create(:proofed_email, name: 'email2', blast: create(:blast, push: create(:push)))
      job = MultiBlastJob.new(email_ids: [email1.id, email2.id], push: push)
      job.should_not be_valid
      job.errors[:email].should == ["'#{email2.id}' is not part of this push"]
    end

    it "validate all blasts have a list" do
      email2 = create(:proofed_email, blast: create(:blast, name: 'blast2', push: create(:push), list: nil))
      job = MultiBlastJob.new(email_ids: [email1.id, email2.id], push: push)
      job.should_not be_valid
      job.errors[:blast].should == ["'#{email2.blast.name}' requires a list in order to send"]
    end

    it "validate all email must be proofed" do
      email2 = create(:email, name: 'email2', blast: create(:blast, push: push))
      job = MultiBlastJob.new(email_ids: [email1.id, email2.id], push: push)
      job.should_not be_valid
      job.errors[:email].should == ["'#{email2.name}' must be proofed"]
    end
    
    it "validate no blasts in current push are currently sending (using delayed_job_id)" do
      email2 = create(:email, blast: create(:blast, delayed_job_id: 1, push: push))
      job = MultiBlastJob.new(email_ids: [email1.id, email2.id], push: push)
      job.should_not be_valid
      job.errors[:push].should == ["is in progress"]
    end

    it "validate email ids are unique" do
      job = MultiBlastJob.new(email_ids: [email1.id, email1.id], push: push)
      job.should_not be_valid
      job.errors[:email].should == ["#{email1.id} appears multiple times"]
    end
  end

  describe "contains_blast?" do
    it "should return true" do
      job = MultiBlastJob.new(email_ids: [email1.id], push: push)
      job.contains_blast?(email1.blast.id).should be true
    end
    it "should return false" do
      blast = create(:blast, push: push)
      job = MultiBlastJob.new(email_ids: [email1.id], push: push)
      job.contains_blast?(blast.id).should be false
    end
  end

  describe "load_job" do
    it "returns nil if job does not exist" do
      MultiBlastJob.load_job(-1).should be_nil
    end
    it "returns nil if job is not a MultiBlastJob" do
      Delayed::Job.enqueue(TestJob.new)
      job = Delayed::Job.last
      MultiBlastJob.load_job(job.id).should be_nil
    end
    it "returns job with delyed job set if job is a MultiBlastJob" do
      Delayed::Job.enqueue(MultiBlastJob.new({}))
      job = Delayed::Job.last
      multiblast_job = MultiBlastJob.load_job(job.id)
      multiblast_job.should be_present
      multiblast_job.job.should == job
    end
  end

  class TestJob
    def perform
    end
  end

  def simulate_worker(job)
    Delayed::Job.enqueue(job)
    delayed_job = Delayed::Job.last
    handler = YAML.load(delayed_job.handler)
    handler.before(delayed_job)
    handler.perform
  end
end
