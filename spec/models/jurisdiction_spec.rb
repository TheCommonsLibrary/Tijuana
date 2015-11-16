require 'spec_helper'

describe "State behaviour" do

  before do
    jurisdiction = {}

    jurisdiction["NSW"] = "New South Wales"
    jurisdiction["QLD"] = "Queensland"
    jurisdiction["VIC"] = "Victoria"
    jurisdiction["SA"] = "South Australia"
    jurisdiction["WA"] = "Western Australia"
    jurisdiction["ACT"] = "Australian Capital Territory"
    jurisdiction["NT"] = "Northern Territory"
    jurisdiction["TAS"] = "Tasmania"
    jurisdiction["FEDERAL"] = "Federal"

    jurisdiction.each do |key, value|
      Jurisdiction.create!(:code => key, :name => value)
    end
  end
  
  it "should give us array of options" do
    Jurisdiction.select_options[0][0].should eql "New South Wales"
    Jurisdiction.select_options[7][0].should eql "Tasmania"
    Jurisdiction.select_options[8][0].should eql "Federal"
  end

  it "should reject federal as a state" do
    Jurisdiction.select_options_for_states.size.should eql 8
  end

  it "should reject other states when select federal" do
    Jurisdiction.select_options_for_federal.size.should eql 1
  end
end