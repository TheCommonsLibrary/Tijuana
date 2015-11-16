require File.expand_path(File.dirname(__FILE__) + "../../spec_helper")


describe ThemeModule do
  include ThemeModule

  context '#layout_path' do
    it "should handle empty" do
      layout_path(nil).should == "application"
      layout_path("").should == "application"
    end

    it "should add theme to path and downcase" do
      layout_path("MYTHEME").should == "themes/mytheme"
    end
  end
end

