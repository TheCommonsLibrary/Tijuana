require File.expand_path(File.dirname(__FILE__) + "../../../spec_helper")
require File.join(File.dirname(__FILE__), 'stats_helper')
require 'stats/transparency_stats'

describe Stats::TransparencyStats do
  it "should load transparency stats data" do
    make_stats_data
    stats = Stats::TransparencyStats.new
    stats.update
    stats = stats.load

    stats.size.should eql 7

    stats[0].name.should eql "Donations"
    stats[0].day.should eql 1
    stats[0].week.should eql 2
    stats[0].month.should eql 3
    stats[0].year.should eql 4

    stats[1].name.should eql "Donations Total"
    stats[1].day.should eql 50
    stats[1].week.should eql 60
    stats[1].month.should eql 80
    stats[1].year.should eql 110

    stats[2].name.should eql "Average Donations"
    stats[2].day.should eql 50
    stats[2].week.should eql 30
    stats[2].month.should eql 26
    stats[2].year.should eql 27

    stats[3].name.should eql "Actions Taken"
    stats[3].day.should eql 1
    stats[3].week.should eql 2
    stats[3].month.should eql 3
    stats[3].year.should eql 4

    stats[4].name.should eql "New Members"
    stats[4].day.should eql 0
    stats[4].week.should eql 1
    stats[4].month.should eql 1
    stats[4].year.should eql 2

    stats[5].name.should eql "Donors"
    stats[5].day.should eql 1
    stats[5].week.should eql 1
    stats[5].month.should eql 2
    stats[5].year.should eql 3

    stats[6].name.should eql "First-time Donors"
    stats[6].day.should eql 0
    stats[6].week.should eql 1
    stats[6].month.should eql 1
    stats[6].year.should eql 2
  end
end
