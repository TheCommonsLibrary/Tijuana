require File.expand_path(File.dirname(__FILE__) + "../../spec_helper")
require 'weekly_user_statistics'

describe WeeklyUserStatistics do

  before do
    Timecop.freeze(8.days.ago) do
      @user1 = create(:user)
    end
    @user2 = create(:user)
    @user3 = create(:user)
    @now = Time.now.to_date
  end

  describe "new members" do
    it "should not include members that signed up prior to the from date" do
      stats = WeeklyUserStatistics.from(@now, 1)
      stats.new_members.should == 2
    end

    it "should count duplicate subscriptions once only" do
      UserActivityEvent.subscribed!(@user2)

      stats = WeeklyUserStatistics.from(@now, 1)
      stats.new_members.should == 2
    end

    it "should everage over the given number of weeks and round to two decimal places" do
      user4 = create(:user)
      stats = WeeklyUserStatistics.from(@now, 3)
      stats.new_members.should be_within(0.01).of 1.33
    end
  end

  describe "unsubscribed members" do

    it "returns 0" do
      stats = WeeklyUserStatistics.from(@now, 1)
      stats.unsubscribed_members.should == 0
    end

    context "with unsubscribed members" do

      before :each do
        Timecop.freeze(8.days.ago) do
          @user1.unsubscribe!()
        end
        @user2.unsubscribe!()
        @user3.unsubscribe!()
      end

      it "should not include members that unsubscribed prior to the from date" do
        stats = WeeklyUserStatistics.from(@now, 1)
        stats.unsubscribed_members.should == 2
      end

      it "should count duplicate unsubscriptions once only" do
        @user2.unsubscribe!()

        stats = WeeklyUserStatistics.from(@now, 1)
        stats.unsubscribed_members.should == 2
      end
    end

  end

  describe "#dropped_members" do

    it "returns 0" do
      stats = WeeklyUserStatistics.from(@now, 1)
      stats.dropped_members.should == 0
    end

    context "with dropped members" do

      before :each do
        Timecop.freeze(8.days.ago) do
          UserActivityEvent.email_dropped!(@user1, 'bounce', Time.now)
        end
        UserActivityEvent.email_dropped!(@user2, 'spam', Time.now)
        UserActivityEvent.email_dropped!(@user3, 'invalid', Time.now)
      end

      it "should not include members that unsubscribed prior to the from date" do
        stats = WeeklyUserStatistics.from(@now, 1)
        stats.dropped_members.should == 2
      end

      it "should count duplicate unsubscriptions once only" do
        UserActivityEvent.email_dropped!(@user2, 'spam', Time.now)

        stats = WeeklyUserStatistics.from(@now, 1)
        stats.dropped_members.should == 2
      end
    end

  end

end
