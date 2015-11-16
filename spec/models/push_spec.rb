require File.expand_path(File.dirname(__FILE__) + "../../spec_helper")

describe Push do
  describe "validations" do
    it "should require a name between 3 and 64 characters" do
      Push.new(:name => "Save the kittens!").should be_valid
      Push.new(:name => "AB").should_not be_valid
      Push.new(:name => "X" * 64).should be_valid
      Push.new(:name => "Y" * 65).should_not be_valid
    end
  end

  before(:each) do
    @now = Time.utc(2000, 1, 1, 5, 0)
    Timecop.freeze(@now)
  end

  after(:each) do
    Timecop.return
  end

  describe "logging activities" do
    without_transactional_fixtures do
      it "should log the given activity against the appropriate push table" do
        user = create(:user)
        email = create(:email)
        push = email.blast.push
        with_push_table(push) do
          Push.log_activity!(:email_viewed, user, email)
          push.count_by_activity(:email_viewed).should eql 1
          push_table_records(push).first.should == [user.id, "email_viewed", email.id, @now]
        end
      end

      it "should batch create user activity events" do
        user_ids = (1..10).collect { create(:user) }.collect(&:id)
        email = create(:email)
        push = email.blast.push
        with_push_table(push) do
          push.batch_create_sent_activity_event!(user_ids, email, 5)

          push.count_by_activity(:email_sent).should eql 10
          events = push_table_records(push).to_a
          events.first.should == [user_ids.first, "email_sent", email.id, @now]
          events.second.should == [user_ids.second, "email_sent", email.id, @now]
          timestamps = events.collect { |r| r.last }
          timestamps.uniq.should == [@now]
        end
      end

      it "should create and destroy push table only on create and destroy" do
        pending "the commit for the .destroy doesn't fire"
        # it works in dev console
        # apparently this is meant to help, but doesn't:
          # https://github.com/grosser/test_after_commit
        # also, it's been fixed again in rails 5

        user = create(:user)
        with_push_table do
          push = create(:push)
          blast = create(:blast, push: push)
          email = create(:email, blast: blast)

          # check push table does not get destroyed and recreated on commit
          has_push_table(push).should be true
          push_table_count(push).should == 0
          Push.log_activity!('email_sent', user, email)
          push_table_count(push).should == 1
          push_table_count(push).should == 1

          push.destroy
          has_push_table(push).should be false
        end
      end
    end
  end

  it "should return whether or not there are blasts currently being sent" do
    Push.any_instance.stub(:create_activities_table)
    push = create(:push)
    in_progress_blast = create(:blast, :push => push, :delayed_job_id => 987)
    blast_1 = create(:blast, :push => push)
    blast_2 = create(:blast, :push => push)

    push.has_pending_jobs?.should be true

    push = create(:push)
    blast_1 = create(:blast, :push => push)

    push.has_pending_jobs?.should be false
  end

  context 'push with blast with email' do
    before :each do
      @push = create(:push)
      @email1 = create(:email, blast: create(:blast, push: @push, list: create(:list)))
      @email2 = create(:email, blast: create(:blast, push: @push, list: create(:list)))
      @email1.send_test!(['dummy@email.com'])
      @email2.send_test!(['dummy@email.com'])
      @email_ids = [@email1.id, @email2.id]
    end

    describe "multiblast_valid?" do
      it "delegates validation to MultiBlast and copies error from multiblast" do
        multiblast_job = double(MultiBlastJob, perform: nil)
        MultiBlastJob.should_receive(:new).with(email_ids: @email_ids, push: @push).and_return(multiblast_job)
        multiblast_job.should_receive(:valid?).and_return(false)
        errors = {error: "message"}
        multiblast_job.stub(errors: errors)
        @push.multiblast_valid?(@email_ids).should be false
        @push.errors.full_messages.first.should == "Error message"
      end
    end

    describe "send_multiblast!" do
      it "enqueues MultiBlastJob to run with blast_job_delay" do
          AppConstants.stub(blast_job_delay: 1.hour)
          @push.send_multiblast!(@email_ids)
          job  = Delayed::Job.last
          handler = YAML.load(job.handler)
          handler.class.should == MultiBlastJob
          job.run_at.should == 1.hour.from_now
      end

      it "enqueues MultiBlastJob with correct mail ids" do
        MultiBlastJob.should_receive(:new).with(email_ids: @email_ids, push: @push).and_return(double(MultiBlastJob, perform: nil, valid?: true))
        @push.send_multiblast!(@email_ids)
      end

      it "sets delayed_job_id on all blasts" do
        MultiBlastJob.should_receive(:new).with(email_ids: @email_ids, push: @push).and_return(double(MultiBlastJob, perform: nil, valid?: true))

        @push.send_multiblast!(@email_ids)
        job = Delayed::Job.last

        @email1.blast.reload.delayed_job_id.should == job.id
        @email2.blast.reload.delayed_job_id.should == job.id
      end

      it "should raise error and not enqueue job if multiblast is not valid" do
        MultiBlastJob.should_receive(:new).with(email_ids: @email_ids, push: @push).and_return(double(MultiBlastJob, valid?: false, errors: {dummy: 'error'}))
        Delayed::Job.should_not_receive(:enqueue)

        expect {
          @push.send_multiblast!(@email_ids)
        }.to raise_error(RuntimeError, /Can not send invalid multiblast: dummy: error/)

        @email1.blast.reload.delayed_job_id.should be_nil
        @email2.blast.reload.delayed_job_id.should be_nil
      end

    end

    describe "sending_multiblast?" do

      it "should be false if not sending" do
        @push.should_not be_sending_multiblast
      end

      it "should be true if sending" do
        @push.send_multiblast!(@email_ids)
        @push.should be_sending_multiblast
      end

    end

    describe "cancel_multiblast!" do

      it "should cancel InterruptableJob" do
        @push.send_multiblast!(@email_ids)
        job = Delayed::Job.last

        InterruptableJob.should_receive(:cancel).with(job.id)
        @push.cancel_multiblast!
      end

      it "should reset delayed job ids if cancel returns STATUS destroyed and return status" do
        @push.send_multiblast!(@email_ids)

        InterruptableJob.stub(cancel: InterruptableJob::CANCEL_STATUS[:destroyed])
        @push.cancel_multiblast!.should == InterruptableJob::CANCEL_STATUS[:destroyed]

        @email1.blast.reload.delayed_job_id.should be_nil
        @email2.blast.reload.delayed_job_id.should be_nil
      end


      it "should not reset delayed job ids if cancel returns STATUS interrupted and return status" do
        @push.send_multiblast!(@email_ids)

        InterruptableJob.stub(cancel: InterruptableJob::CANCEL_STATUS[:interrupted])
        @push.cancel_multiblast!.should == InterruptableJob::CANCEL_STATUS[:interrupted]

        @email1.blast.reload.delayed_job_id.should be_present
        @email2.blast.reload.delayed_job_id.should be_present
      end

      it "should return nil if no blast job ids" do
        subject.stub(blast_job_ids: [])
        @push.cancel_multiblast!.should be_nil
      end

    end


    describe "multiblast_contains_blast?" do

      it "returns true if blast is being sent by current multiblast job" do
        @push.send_multiblast!(@email_ids)
        @push.multiblast_contains_blast?(@email1.blast.id).should be true
      end

      it "returns false if blast is not being sent by current multiblast job" do
        other_blast = create(:blast, push: @push, list: create(:list))
        @push.send_multiblast!(@email_ids)
        @push.multiblast_contains_blast?(other_blast.id).should be false
      end

      it "returns false if no blast is being sent" do
        @push.multiblast_contains_blast?(@email1.blast.id).should be false
      end
    end


    describe "cancelling_multiblast?" do

      it "should be true if cancel called when locked" do
        @push.send_multiblast!(@email_ids)
        job = Delayed::Job.last
        InterruptableJob.acquire_lock(job.id)
        @push.cancel_multiblast!

        @push.should be_cancelling_multiblast
      end

      it "should be false" do
        @push.should_not be_cancelling_multiblast
      end
    end
  end

  describe "#has_been_sent?" do
    let(:push) { create(:push) }
    let(:blast) { create(:blast, push: push) }
    let(:email) { create(:email, blast: blast) }

    context "no emails sent" do
      specify { push.has_been_sent?.should == false }
    end

    context "an email has been sent" do
      before { create(:sent_email, email: email) }
      specify { push.has_been_sent?.should == true }
    end
  end

  describe "#duplicate" do
    without_transactional_fixtures do
      let!(:push) { create(:push) }
      let!(:blast) { create(:blast, push: push) }
      let!(:email) { create(:email, blast: blast) }
      let!(:list) { create(:list, blast: blast) }
      before do
        list.set_email_domain_rule(:domain => "@gmail.com")
        list.save!
        push.reload
      end
    
      it "should create a duplicated push" do
        new_push = push.duplicate
        expect(new_push).to be_valid
        expect(new_push.name).to match(/#{push.name} \[clone/)
      end
    
      it "should duplicated the emails" do
        new_push = push.duplicate
        expect(new_push.blasts.first.emails.first.body).to eq(email.body)
      end
    
      it "should duplicated the list" do
        new_push = push.duplicate
        push.duplicate
        expect(new_push.blasts.first.list.rules).to_not be_empty
      end
    end
  end

  private

  def push_table_records(push)
    ActiveRecord::Base.connection.execute("SELECT * FROM push_#{push.id}")
  end

  def push_table_count(push)
    ActiveRecord::Base.connection.execute("SELECT * FROM push_#{push.id}").count
  end

  def has_push_table(push)
    ActiveRecord::Base.connection.execute("show tables like 'push_#{push.id}'").count == 1
  end
end
