require 'timecop'

require File.expand_path(File.dirname(__FILE__) + "../../../spec_helper")
require File.join(File.dirname(__FILE__), 'stats_helper')
require 'stats/financial_year_stats'

describe Stats::FinancialYearStats do
  let(:fy_stats) { Stats::FinancialYearStats.new }

  after(:each) { Timecop.return }

  describe "#last_financial_year" do
    {
      Time.local(2012, 8, 30, 17, 00, 00) => {
        :start => Time.local(2011, 7, 1), 
        :end => Time.local(2012, 6, 30, 23, 59, 59) 
      },
      Time.local(2013, 3, 22, 12, 00, 00) => {
        :start => Time.local(2011, 7, 1), 
        :end => Time.local(2012, 6, 30, 23, 59, 59) 
      },
      Time.local(2013, 10, 14, 12, 00, 00) => {
        :start => Time.local(2012, 7, 1), 
        :end => Time.local(2013, 6, 30, 23, 59, 59) 
      },
      Time.local(2011, 8, 30, 17, 00, 00) => {
        :start => Time.local(2010, 7, 1), 
        :end => Time.local(2011, 6, 30, 23, 59, 59) 
      }
    }.each do |date, financial_year|
      it "should calculate the start and end dates of the most recent complete financial year for the date #{date.strftime('%d-%m-%Y')}" do
        Timecop.travel(date)
        fy_stats.last_financial_year[:start].should == financial_year[:start]
        fy_stats.last_financial_year[:end].should == financial_year[:end]
      end
    end
  end

  describe "calculations" do
    before :each do
      Timecop.travel(Time.local(2012, 8, 31, 17, 0, 0))
      make_stats_data
    end

    {
      :subscribed => 1,
      :action_taken => 2
    }.each do |activity, count|
      it "should calculate the number of #{activity == :subscribed ? 'subscriptions' : 'actions taken'}" do
        fy_stats.activities(activity).should == count
      end
    end

    it "should calculate the average donation amount" do
      fy_stats.average_donation_amount.should == 30
    end

    it "should calculate the number_of_donations" do
      fy_stats.number_of_donations.should == 2
    end

    it "should calculate the number_of_donors" do
      fy_stats.number_of_donors.should == 2
    end

    it "should calculate the average total donation per donation" do
      fy_stats.average_total_donation_per_donor.should == 30
    end
  end
end
