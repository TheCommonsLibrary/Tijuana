require File.expand_path(File.dirname(__FILE__) + "../../spec_helper")
include ActionView::Helpers::NumberHelper

describe Homepage do
  describe "banner html" do  
    it "substitutes {MEMBERCOUNT} for current members" do
      MemberCountCalculator.init
      MemberCountCalculator.set_count(170032)
      homepage = Homepage.new
      homepage.banner_text = "We have {MEMBERCOUNT} members!"
      homepage.banner_html.should == "We have <span id=\"member-count\">170,032</span> members!"
    end
  end
end
