require File.expand_path(File.dirname(__FILE__) + "../../spec_helper")

describe DateTimeHelper do
  it "should format original datetime to 'dd-mm-yyyy hh:mm'" do
    original_datetime = DateTime.new(2015, 2, 3, 4, 5, 6,'+10')
    helper.remove_second_and_time_zone(original_datetime).should == "03-02-2015 04:05"
  end
end
