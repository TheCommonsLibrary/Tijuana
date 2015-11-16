require File.expand_path(File.dirname(__FILE__) + "../../spec_helper")

describe InterruptableJob do

  class TestInterruptableJob
    include InterruptableJob

    def perform
      'never runs'
    end
  end

  describe 'lock' do

    it "sets locked_at" do
      Delayed::Job.enqueue(TestInterruptableJob.new)
      job = Delayed::Job.last
      InterruptableJob.acquire_lock(job.id)
      job.reload
      job.locked_at.should be_present
    end

  end

  describe "destroy" do

    it "destroys jobs that have been locked" do
      Delayed::Job.enqueue(TestInterruptableJob.new)
      job = Delayed::Job.last
      InterruptableJob.acquire_lock(job.id)
      InterruptableJob.destroy(job.id)
      Delayed::Job.exists?(job.id).should be false
    end

    it "does not destroy jobs that have not been locked but raise error" do
      Delayed::Job.enqueue(TestInterruptableJob.new)
      job = Delayed::Job.last
      expect(job).to be_present
      expect {
        InterruptableJob.destroy(job.id)
      }.to raise_error(RuntimeError, /has not been locked/)
      Delayed::Job.exists?(job.id).should be true
    end

  end

  describe "handler#interrupted?" do

    it "indicates whether job has been interrupted" do
      Delayed::Job.enqueue(TestInterruptableJob.new)
      job = Delayed::Job.last
      handler = YAML.load(job.handler)
      handler.before(job) #This simulates worker lifecycle
      handler.should_not be_interrupted
      InterruptableJob.interrupt(job.id)
      handler.should be_interrupted
    end

  end

  describe ".interrupted?" do

    it "indicates whether job has been interrupted" do
      Delayed::Job.enqueue(TestInterruptableJob.new)
      job = Delayed::Job.last

      InterruptableJob.interrupted?(job.id).should be false
      InterruptableJob.interrupt(job.id)
      InterruptableJob.interrupted?(job.id).should be true
    end

  end

  describe 'cancel' do
    it 'destroys job if it is not running' do
      Delayed::Job.enqueue(TestInterruptableJob.new)
      job = Delayed::Job.last
      InterruptableJob.cancel(job.id).should == InterruptableJob::CANCEL_STATUS[:destroyed]
      Delayed::Job.exists?(job.id).should be false
    end

    it 'interrupts job if it is locked (eg. running in worker)' do
      Delayed::Job.enqueue(TestInterruptableJob.new)
      job = Delayed::Job.last
      InterruptableJob.acquire_lock(job.id)

      InterruptableJob.cancel(job.id).should == InterruptableJob::CANCEL_STATUS[:interrupted]
      Delayed::Job.exists?(job.id).should be true
      InterruptableJob.interrupted?(job.id).should be true
    end
  end



end
