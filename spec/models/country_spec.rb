require File.expand_path(File.dirname(__FILE__) + "../../spec_helper")

describe Country do
    it "should produce a list for a Rails select helper" do
    options = Country.select_options
    options.first.should == ["AUSTRALIA", "AU"]
  end
end