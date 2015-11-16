require File.expand_path(File.dirname(__FILE__) + "../../spec_helper")

describe RadioStation do
  before(:each) do
    create(:radio_station, :name => "Surry Hills", :longitude => 151.20, :latitude => -33.86, :broadcast_radius => 50)
    create(:radio_station, :name => "Penrith", :longitude => 150.686829, :latitude => -33.74718, :broadcast_radius => 5)
    create(:radio_station, :name => "Katoomba", :longitude => 150.315353, :latitude => -33.708919, :broadcast_radius => 100)
    create(:radio_station, :name => "Griffith", :longitude => 146.055542, :latitude => -34.279914, :broadcast_radius => 50)
    create(:radio_station, :name => "Dubbo", :longitude => 148.620849, :latitude => -32.240682, :broadcast_radius => 50)
  end

  it "should import a radio station data" do
    create(:radio_station)
    RadioStation.find_by_name("Surry Hills").should_not be nil
  end

  it "should not allow string in broadcast radius" do
    radio = build(:radio_station, :broadcast_radius => "qwe")
    radio.valid?.should be false
  end

end
