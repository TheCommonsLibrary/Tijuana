require File.expand_path(File.dirname(__FILE__) + "../../spec_helper")

describe DashboardHelper do
  describe "#mask_card_number" do
    it "should right justify the card's last 4 digits with Xs'"  do
      helper.mask_card_number("1234565678902367").should eql "XXXX XXXX XXXX 2367"
      helper.mask_card_number(nil).should eql "XXXX XXXX XXXX XXXX"
    end
  end

  describe "#month_options" do
    it "should build month options to be used by the select tag helper" do
      helper.month_options.should eql [["Jan", 1], ["Feb", 2], ["Mar", 3], ["Apr", 4], ["May", 5], ["Jun", 6], ["Jul", 7], ["Aug", 8], ["Sep", 9], ["Oct", 10], ["Nov", 11], ["Dec", 12]]
    end
  end

  describe "#year_options" do
    it "should build year options" do
      Date.stub(:today) { double(year: 2011) }
      helper.year_options.should eql [["2011", "2011"], ["2012", "2012"], ["2013", "2013"], ["2014", "2014"], ["2015", "2015"], ["2016", "2016"], ["2017", "2017"]]
    end
  end
end
