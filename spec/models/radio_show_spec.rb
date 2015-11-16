require 'spec_helper'

describe RadioShow do
  before(:each) do
    surry_station = create(:radio_station, :name => "Surry Hills", :longitude => 151.20, :latitude => -33.86, :broadcast_radius => 50)
    penrith_station = create(:radio_station, :name => "Penrith", :longitude => 150.686829, :latitude => -33.74718, :broadcast_radius => 5)
    katoomba_station = create(:radio_station, :name => "Katoomba", :longitude => 150.315353, :latitude => -33.708919, :broadcast_radius => 100)
    griffith_station = create(:radio_station, :name => "Griffith", :longitude => 146.055542, :latitude => -34.279914, :broadcast_radius => 50)
    dubbo_station = create(:radio_station, :name => "Dubbo", :longitude => 148.620849, :latitude => -32.240682, :broadcast_radius => 50)

    time_now = Time.utc(2012, "feb", 9, 1, 15, 1)
    Time.stub(:now) { time_now }

    same_date = Date.civil(2012, 2, 9)
    Date.stub(:today) { same_date }

    @from_time = Time.utc(2012, "feb", 9, 0, 0, 1)
    @to_time = Time.utc(2012, "feb", 9, 3, 0, 1)

    @surry_show = create(:radio_show, :name => "Surry Show", :presenter => "Surry Hero", :from_time =>@from_time, :to_time => @to_time, :radio_station_id => surry_station.id)
    create(:radio_show, :name => "Penrith Show", :presenter => "Penrith Hero", :from_time =>@from_time, :to_time => @to_time, :radio_station_id => penrith_station.id)
    create(:radio_show, :name => "Katoomba Show", :presenter => "Katoomba Hero", :from_time =>@from_time, :to_time => @to_time, :radio_station_id => katoomba_station.id)
    create(:radio_show, :name => "Griffith Show", :presenter => "Griffith Hero", :from_time =>@from_time, :to_time => @to_time, :radio_station_id => griffith_station.id)
    create(:radio_show, :name => "Dubbo Show", :presenter => "Dubbo Hero", :from_time =>@from_time, :to_time => @to_time, :radio_station_id => dubbo_station.id)

  end

  it "should select shows when the show runs across midnight" do
    @surry_show.from_time = Time.utc(2012, "feb", 9, 4, 15, 1)
    @surry_show.to_time = Time.utc(2012, "feb", 9, 6, 15, 1)
    @surry_show.save!

    shows = RadioShow.find_radio_shows(-33.86, 151.21)
    shows[:now].collect { |show| show.name }.should include "Katoomba Show"
    shows[:now].collect { |show| show.name }.should_not include "Surry Show"
  end

  it "shouldn't select shows that start one hour later" do
    @surry_show.from_time = Time.utc(2012, "feb", 8, 22, 15, 1)
    @surry_show.to_time = Time.utc(2012, "feb", 9, 2, 15, 1)
    @surry_show.save!

    shows = RadioShow.find_radio_shows(-33.86, 151.21)
    shows[:now].collect { |show| show.name }.should include "Katoomba Show", "Surry Show"
  end

  it "should show radio stations in Sydney and weed out the ones that are over" do
    @surry_show.from_time = Time.utc(2012, "feb", 8, 22, 15, 1)
    @surry_show.to_time = Time.utc(2012, "feb", 9, 0, 0, 1)
    @surry_show.save!

    shows = RadioShow.find_radio_shows(-33.86, 151.21)
    shows[:now].collect { |show| show.name }.should eql ["Katoomba Show"]
    shows[:not_now].collect { |show| show.name }.should eql ["Surry Show"]

  end

  it "should show radio stations in sydney" do
    shows = RadioShow.find_radio_shows(-33.86, 151.21)
    shows[:now].collect { |show| show.name }.should include "Surry Show", "Katoomba Show"
    shows[:not_now].size.should be 0
  end

  it "should have from and to time" do
    RadioShow.find_by_presenter("Surry Hero").should_not be nil
    RadioShow.find_by_from_time_and_to_time(@from_time, @to_time).should_not be nil
  end

  it "should allow nil website " do
    create(:radio_show, :website => nil)
    RadioShow.find_by_presenter("Surry Hero").should_not be nil
  end

  it "should show no radio stations if radio stations are not in sydney" do
    stations = RadioShow.find_radio_shows(-33.86, 251.21)
    stations[:now].size.should be 0
    stations[:not_now].size.should be 0
  end

  it "should have correct from and to dates" do
    from_time_for_perth_show = "09:02:34"
    to_time_for_perth_show = "22:01:23"

    perth_station = create(:radio_station, :name => "Perth", :state => "WA", :longitude => 170.20, :latitude => -35.86, :broadcast_radius => 50)
    radio_ga_ga = create(:radio_show, :name => "Radio ga ga", :presenter => "queen", :from_time =>from_time_for_perth_show, :to_time => to_time_for_perth_show, :radio_station_id => perth_station.id)

    radio_ga_ga.parse_time(:from_time, from_time_for_perth_show, "WA")
    radio_ga_ga.parse_time(:to_time, to_time_for_perth_show, "WA")
    radio_ga_ga.save!

    show = RadioShow.find_by_name("Radio ga ga")

    show.from_time.in_time_zone("Australia/Perth").strftime("%H:%M:%S").should eql from_time_for_perth_show
    show.to_time.in_time_zone("Australia/Perth").strftime("%H:%M:%S").should eql to_time_for_perth_show

    show.from_time_localised.should eql " 9:02 am"
    show.to_time_localised.should eql "10:01 pm"
  end

end
