require File.expand_path(File.dirname(__FILE__) + "../../spec_helper")

describe FormattingHelper do

  it "should return a pretty date" do
    helper.pretty_date(Time.new "2525/1/1").should == "Monday,  1 January 2525"
  end

  it "should return empty string for nil" do
    helper.pretty_date(nil).should == ""
    helper.pretty_time(nil, nil).should == ""
  end

  it "should prettify a time passed as integer" do
    helper.pretty_time(0, Date.new).should include "12:00 am"
    helper.pretty_time(1200, Date.new).should include "12:00 pm"
    helper.pretty_time(1215, Date.new).should include "12:15 pm"
    helper.pretty_time(1730, Date.new).should include "5:30 pm"
    helper.pretty_time(245, Date.new).should include "2:45 am"
  end

end
