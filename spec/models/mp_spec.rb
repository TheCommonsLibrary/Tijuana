require File.expand_path(File.dirname(__FILE__) + "../../spec_helper")

describe Mp do
  before(:each) do
    @nsw = create(:nsw_jurisdiction)
    @tas = create(:tas_jurisdiction)
    @nsw_electorate = create(:electorate, jurisdiction: @nsw)
    @tas_electorate = create(:electorate, jurisdiction: @tas)
  end

  it "should allow only one MP per electorate" do
    @nsw_mp1 = create(:mp, electorate: @nsw_electorate)
    @nsw_electorate.reload
    @nsw_mp1.valid?.should be true
    @nsw_mp2 = build(:mp, electorate: @nsw_electorate)
    @nsw_electorate.reload
    @nsw_mp2.valid?.should be false
    @nsw_mp2.errors[:electorate][0].should match("too many MPs")
  end

  it "should allow multiple MPs per party for electorates in TAS" do
    @tas_mp1 = create(:mp, party: @tas_party, electorate: @tas_electorate)
    @tas_mp2 = build(:mp, party: @tas_party, electorate: @tas_electorate)
    @tas_mp2.save.should be true
  end

  it "cleans email addresses of spaces & newlines before validation" do
    create(:mp, email: " qwe@example.com\n").should be_valid
  end
end
