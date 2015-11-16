require File.expand_path(File.dirname(__FILE__) + "../../spec_helper")

describe ContentModuleLink do
  describe "acts as list" do
    it "should be scoped to the containing page and the layout container" do
      page = create(:page_with_parent)
      another_page = create(:page_with_parent)
      3.times { ContentModuleLink.create!(:content_module => create(:html_module), :page => another_page, :layout_container => :main_content) }
      
      first_link = ContentModuleLink.create!(:content_module => create(:html_module), :page => page, :layout_container => :sidebar)
      second_link = ContentModuleLink.create!(:content_module => create(:html_module), :page => page, :layout_container => :sidebar)
      first_link.position.should == 1
      second_link.position.should == 2
      
      third_link = ContentModuleLink.create!(:content_module => create(:html_module), :page => page, :layout_container => :main_content)
      third_link.position.should == 1
    end
  end
end