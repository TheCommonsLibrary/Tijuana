require 'spec_helper'

describe RadiosController do

  before(:each) do
    @radio_module = create(:radio_module)
    surry_station = create(:radio_station, :name => "Surry Radio", :longitude => 151.20, :latitude => -33.86, :broadcast_radius => 50)

    @surry_show = create(:radio_show, :name => "Surry Show", :presenter => "Surry Curry", :from_time => 1.hours.ago, :to_time => 1.hour.from_now, :radio_station_id => surry_station.id)

    create(:postcode, :number => "2010", :longitude => 151.20, :latitude => -33.86)
    create(:postcode, :number => "2750", :longitude => 150.686829, :latitude => -33.74718)
    create(:postcode, :number => "2780", :longitude => 150.315353, :latitude => -33.708919)
    create(:postcode, :number => "2680", :longitude => 146.055542, :latitude => -34.279914)
    create(:postcode, :number => "2830", :longitude => 148.620849, :latitude => -32.240682)
  end

  render_views
  describe "lookup" do

    it "should return an error if the user enters an invalid postcode" do
      get :lookup, {:postcode => 99999}
      @msg = assigns(:msg)
      @msg.should =~ /Please enter a valid postcode./
      @shows_now = assigns(:shows_now)
      @shows_now.should be_empty
      @shows_not_now = assigns(:shows_not_now)
      @shows_not_now.should be_empty
    end

    it "should return empty options if the post code is valid and no radio stations found" do
      get :lookup, {:postcode => 2830}
      @msg = assigns(:msg)
      @msg.should =~ /No shows in your location./
      @shows_now = assigns(:shows_now)
      @shows_now.should be_empty
      @shows_not_now = assigns(:shows_not_now)
      @shows_not_now.should be_empty
    end

  end
end

