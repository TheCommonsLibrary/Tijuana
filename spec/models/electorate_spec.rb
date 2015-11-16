require File.expand_path(File.dirname(__FILE__) + "../../spec_helper")

describe Electorate do
  before(:each) do
    @tas_jurisdiction = create(:tas_jurisdiction)
    @nsw_jurisdiction = create(:nsw_jurisdiction)
    @tas_electorate = create(:electorate, jurisdiction: @tas_jurisdiction)
    @nsw_electorate = create(:electorate, jurisdiction: @nsw_jurisdiction)
    @tas_mp = create(:mp, electorate: @tas_electorate)
    @nsw_mp = create(:mp, electorate: @nsw_electorate)
  end

  it "should not allow more than one MP per electorate, unless the electorate belongs to TAS" do
    @nsw_mp2 = create(:mp, electorate: @nsw_electorate)
    @nsw_electorate.reload
    @nsw_electorate.valid?.should == false
    @nsw_electorate.errors[:mps][0].should match("can have up to one MP")

    @tas_mp2 = create(:mp, electorate: @tas_electorate)
    @tas_electorate.reload
    @tas_electorate.valid?.should == true
  end
end
