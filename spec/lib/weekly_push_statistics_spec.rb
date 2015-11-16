require File.expand_path(File.dirname(__FILE__) + "../../spec_helper")
require 'weekly_push_statistics'

describe WeeklyPushStatistics do
  before(:all) { DatabaseCleaner.strategy = :truncation }

  with_push_table do
    before :all do
      old_push = create(:push, name: 'old push')
      new_push = create(:push, name: 'new push')
      newest_push = create(:push, name: 'newest push')
      old_blast = create(:blast, name: 'old blast', push: old_push, sent_at: 8.days.ago)
      @new_blast = create(:blast, name: 'new blast', push: new_push, sent_at: 6.days.ago)
      @newest_blast = create(:blast, name: 'newest blast', push: newest_push, sent_at: 1.days.ago)
      @old_email = create(:email, blast: old_blast)
      @new_email = create(:email, blast: @new_blast)
      @newest_email = create(:email, blast: @newest_blast)
      another_email_in_same_push = create(:email, blast: create(:blast, sent_at: 1.day.ago, push: @newest_email.blast.push))
      old_sent_email = create(:sent_email, email: @old_email, subject: @old_email.subject, body: @old_email.body, recipient_count: 1, sql: 'sql', created_at: 8.days.ago )
      new_sent_email = create(:sent_email, email: @new_email, subject: @new_email.subject, body: @new_email.body, recipient_count: 2, sql: 'sql', created_at: 6.days.ago )
      newest_sent_email = create(:sent_email, email: @newest_email, subject: @newest_email.subject, body: @newest_email.body, recipient_count: 2, sql: 'sql', created_at: 1.days.ago )

      user1 = create(:user)
      user2 = create(:user)

      Push.log_activity!("email_sent", user1, @old_email)
      Push.log_activity!("email_sent", user1, @new_email)
      Push.log_activity!("email_sent", user2, @new_email)
      Push.log_activity!("email_sent", user1, @newest_email)
      Push.log_activity!("email_sent", user2, @newest_email)

      Push.log_activity!("email_viewed", user1, @old_email)
      Push.log_activity!("email_viewed", user1, @new_email)
      Push.log_activity!("email_viewed", user2, @new_email)
      Push.log_activity!("email_viewed", user1, @newest_email)
      Push.log_activity!("email_viewed", user2, @newest_email)

      Push.log_activity!("email_clicked", user1, @old_email)
      Push.log_activity!("email_clicked", user1, @new_email)
      Push.log_activity!("email_clicked", user2, @new_email)
      Push.log_activity!("email_clicked", user1, @newest_email)

      petition_module = create(:petition_module, :public_activity_stream_template => "Someone signed!")
      page = create(:page_with_parent)
      UserActivityEvent.subscribed!(user2, page, petition_module)
      UserActivityEvent.action_taken!(user2, page, petition_module, petition_module, @new_email)
      UserActivityEvent.action_taken!(user2, page, petition_module, petition_module, @new_email)
      UserActivityEvent.action_taken!(user2, page, petition_module, petition_module, @old_email)

      @stats = WeeklyPushStatistics.from(1.second.ago, 1)
      @stats_from_two_weeks = WeeklyPushStatistics.from(1.second.ago, 2)
    end
  end

  after :all do
    DatabaseCleaner.clean
    DatabaseCleaner.strategy = :transaction
  end

  describe 'group_stats' do
    describe "views from sends" do
      it "should not include pushes that are older than the from date" do
        @stats.group_stats[:views_from_sends].should == 1
      end

      it "should not double count pushes that have multiple email in the same push" do
        @stats.group_stats[:views_from_sends].should == 1
      end
    end

    describe "clicks from sends" do
      it "should not include pushes that are older than the from date" do
        @stats.group_stats[:clicks_from_sends].should == 0.75
      end
    end

    describe "clicks from views" do
      it "should not include pushes that are older than the from date" do
        @stats.group_stats[:clicks_from_views].should == 0.75
      end
    end

    describe "actions from clicks" do
      it "should only include unique action_taken in right date range for current emails" do
        @stats.group_stats[:actions_from_clicks].should == 1/3.to_f
      end
    end

    describe "average sends" do
      it "should return an average total sends by the number of weeks" do
        @stats.group_stats[:average_sends].should == 4
        @stats_from_two_weeks.group_stats[:average_sends].should == 2.5
      end
    end

    describe "average emails" do
      it "should return an average total emails by the number of weeks" do
        @stats.group_stats[:average_emails].should == 2
        @stats_from_two_weeks.group_stats[:average_emails].should == 3/2.to_f
      end
    end
  end

  describe 'individual statistics' do
    it 'should order created_at date DESC' do
      @stats.individual_stats.count.should == 2

      blasts = [@newest_blast, @new_blast]
      counter = 0

      @stats.individual_stats.each_value do |stat|
        stat[:blast_name].should == blasts[counter].name
        counter += 1
      end
    end

    it 'should contain the email subject' do
      @stats.individual_stats[@newest_email.id][:subject].should == @newest_email.subject
      @stats.individual_stats[@new_email.id][:subject].should == @newest_email.subject
      @stats.individual_stats[@old_email.id].should be_nil
    end

    it 'should contain the push name' do
      @stats.individual_stats[@newest_email.id][:push_name].should == @newest_email.blast.push.name
      @stats.individual_stats[@new_email.id][:push_name].should == @new_email.blast.push.name
      @stats.individual_stats[@old_email.id].should be_nil
    end

    it 'should contain the blast name' do
      @stats.individual_stats[@newest_email.id][:blast_name].should == @newest_email.blast.name
      @stats.individual_stats[@new_email.id][:blast_name].should == @new_email.blast.name
      @stats.individual_stats[@old_email.id].should be_nil
    end

    it 'should contain the sent date' do
      @stats.individual_stats[@newest_email.id][:sent_date].should == @newest_email.blast.sent_at.strftime("%^a")
      @stats.individual_stats[@new_email.id][:sent_date].should == @new_email.blast.sent_at.strftime("%^a")
      @stats.individual_stats[@old_email.id].should be_nil
    end

    it 'should contain number of sends' do
      @stats.individual_stats[@newest_email.id][:sends].should == 2
      @stats.individual_stats[@new_email.id][:sends].should == 2
      @stats.individual_stats[@old_email.id].should be_nil
    end

    describe "views from sends" do
      it "should not include pushes that are older than the from date" do
        @stats.individual_stats[@newest_email.id][:views_from_sends].should == 1
        @stats.individual_stats[@new_email.id][:views_from_sends].should == 1
        @stats.individual_stats[@old_email.id].should be_nil
      end
    end

    describe "clicks from sends" do
      it "should not include pushes that are older than the from date" do
        @stats.individual_stats[@newest_email.id][:clicks_from_sends].should == 0.5
        @stats.individual_stats[@new_email.id][:clicks_from_sends].should == 1
        @stats.individual_stats[@old_email.id].should be_nil
      end
    end

    describe "clicks from views" do
      it "should not include pushes that are older than the from date" do
        @stats.individual_stats[@newest_email.id][:clicks_from_views].should == 0.5
        @stats.individual_stats[@new_email.id][:clicks_from_views].should == 1.0
        @stats.individual_stats[@old_email.id].should be_nil
      end
    end

    describe "actions from clicks" do
      it "should only include unique action_taken in right date range for current emails" do
        @stats.individual_stats[@newest_email.id][:actions_from_clicks].should == 0
        @stats.individual_stats[@new_email.id][:actions_from_clicks].should == 0.5
        @stats.individual_stats[@old_email.id].should be_nil
      end
    end
  end
end
