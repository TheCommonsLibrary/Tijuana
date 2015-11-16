require File.expand_path(File.dirname(__FILE__) + "../../spec_helper")

describe BlastJob do
  let(:no_jobs) { 1 }
  let(:current_job_id) { 0 }
  let(:limit) { 10 }
  let(:user_ids) { [1, 2, 3] }
  let(:email) { create(:email, :test_sent_at => Time.local(2012, 1, 1, 12, 0, 0), :delayed_job_id => 10, :cut_completed_at => nil) }
  let(:list) { List.create! }

  before(:each) do
    ActionMailer::Base.deliveries = []
  end

  it "should perform the job" do
    Timecop.freeze(Time.local(2012, 1, 1, 12, 0, 0)) do
      list.should_receive(:filter_by_rules_excluding_users_from_push).with(email.blast.push, hash_including(
          :limit => limit,
          :no_jobs => no_jobs,
          :current_job_id => current_job_id
      )).and_return(user_ids)

      list.should_receive(:get_sql_query_string_for_dashboard_user).and_return("I AM SQL")

      email.should_receive(:deliver_blast_in_batches).with(user_ids)
      email.delayed_job_id.should_not be_nil

      job = BlastJob.new({
                             :no_jobs => no_jobs,
                             :current_job_id => current_job_id,
                             :list => list,
                             :email => email,
                             :limit => limit
                         })
      job.perform
      job.should_not_receive(:synchronise_blasts)

      sent_emails = SentEmail.where(email_id: email.id)
      sent_emails.count.should == 1
      sent_emails.first.subject.should == email.subject
      sent_emails.first.body.should == email.body
      sent_emails.first.recipient_count.should == user_ids.count
      sent_emails.first.sql.should == "I AM SQL"

      email.delayed_job_id.should be_nil
      email.blast.sent_at.should_not be_nil
      email.blast.sent_at.should eql Time.local(2012, 1, 1, 12, 0, 0)
    end
  end

  without_transactional_fixtures do
    it "should call synchronise_blasts if number of job is more then one" do
      with_push_table('some args') do
        Push.transaction do
          # Need to create email, blast and push in a transaction for the post-commit create push table to fire
          email
        end
        job = BlastJob.new({
                               :no_jobs => 2,
                               :current_job_id => current_job_id,
                               :list => list,
                               :email => email,
                               :limit => limit
                           })

        job.should_receive(:synchronise_blasts)
        job.perform
      end
    end
  end

  it "if a slice fails, continue, log, do not throw exception, and unlock records after completion" do
    user_ids = (1..2000)
    Timecop.freeze(Time.local(2012, 1, 1, 12, 0, 0)) do
      list.should_receive(:filter_by_rules_excluding_users_from_push).with(email.blast.push, hash_including(:limit => limit, :no_jobs => 1, :current_job_id => current_job_id)).and_return(user_ids)
      second_slice = nil
      email.should_receive(:deliver_slice) { raise "DeliverSliceError" } # first slice fails
      email.should_receive(:deliver_slice) { |slice| second_slice = slice } # second slice good
      job = BlastJob.new({
                             :no_jobs => no_jobs,
                             :current_job_id => current_job_id,
                             :list => list,
                             :email => email,
                             :limit => limit
                         })
      job.perform
      second_slice.should == (1001..2000).to_a 
      email.reload
      email.delayed_job_id.should be_nil
      email.blast.sent_at.should_not be_nil
      PushLog.count.should eql 1
      ActionMailer::Base.should have(1).deliveries
      ActionMailer::Base.deliveries.first[:subject].to_s.should match('DeliverSliceError')
    end
  end


  it "if list cut fails, log, do not throw exception, and unlock records after completion" do
    Timecop.freeze(Time.local(2012, 1, 1, 12, 0, 0)) do
      list.should_receive(:filter_by_rules_excluding_users_from_push).with(email.blast.push, hash_including(:limit => limit, :no_jobs => 1, :current_job_id => current_job_id)).and_return(user_ids)

      email.should_receive(:deliver_blast_in_batches).with(user_ids).and_raise 'ListCutFailed'

      job = BlastJob.new({
                             :no_jobs => no_jobs,
                             :current_job_id => current_job_id,
                             :list => list,
                             :email => email,
                             :limit => limit
                         })

      job.perform

      email.reload
      email.delayed_job_id.should be_nil
      email.blast.sent_at.should be_nil
      PushLog.count.should eql 1
      ActionMailer::Base.should have(1).deliveries
      ActionMailer::Base.deliveries.first[:subject].to_s.should match('ListCutFailed')
    end
  end


  describe ".last_job_in_blast?" do
    it "should be true when proofed emails have no running jobs" do
      blast = create(:blast)
      email.stub(:blast).and_return(blast)
      blast.stub(:proofed_emails).and_return(email)
      email.should_receive(:where).with("delayed_job_id IS NOT NULL").and_return([])

      job = BlastJob.new({
                             :no_jobs => no_jobs,
                             :current_job_id => current_job_id,
                             :list => list,
                             :email => email,
                             :limit => limit
                         })
      job.send(:last_job_in_blast?, email).should eql true
    end
  end

  describe "all_blasts_cut?" do
    it "should return true when all emails being blasted have had their lists cut" do
      blast = create(:blast)
      email1 = create(:email, :blast_id => blast.id, :delayed_job_id => 10, :cut_completed_at => Time.local(2012, 1, 1, 12, 10, 0))
      email2 = create(:email, :blast_id => blast.id, :delayed_job_id => 10, :cut_completed_at => Time.local(2012, 1, 1, 12, 10, 0))
      email3 = create(:email, :blast_id => blast.id, :delayed_job_id => 10, :cut_completed_at => nil)

      Timecop.freeze(Time.local(2012, 1, 1, 12, 0, 0)) { email1.send_test!(['dummy@email.com']) }
      Timecop.freeze(Time.local(2012, 1, 1, 12, 0, 0)) { email2.send_test!(['dummy@email.com']) }

      job = BlastJob.new({
                             :no_jobs => 2,
                             :current_job_id => current_job_id,
                             :list => list,
                             :email => email1,
                             :limit => limit
                         })

      job.send(:all_blasts_cut?, email1).should eql true
    end

  end

  describe "synchronise_blasts" do
    it "should sycnhronise the blasts until all of them have cut their lists" do
      job = BlastJob.new({
                             :no_jobs => 2,
                             :current_job_id => current_job_id,
                             :list => list,
                             :email => email,
                             :limit => limit
                         })

      Time.stub(:now).and_return(Time.local(2012, 1, 1, 12, 0, 0))
      job.should_receive(:all_blasts_cut?).and_return(true)
      job.should_receive(:log).with("Detected completion of blast cuts.")
      job.send(:synchronise_blasts)
    end
  end

end
