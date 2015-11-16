require File.expand_path(File.dirname(__FILE__) + "../../spec_helper")

describe BookmarkedContentModule do
  describe "validation" do  
    it "must have a valid name" do
      BookmarkedContentModule.new(:content_module => create(:html_module), :name => nil).should_not be_valid
      BookmarkedContentModule.new(:content_module => create(:html_module), :name => "An").should_not be_valid
      BookmarkedContentModule.new(:content_module => create(:html_module), :name => "An interesting widget").should be_valid
    end
    
    it "must have a unique name" do
      BookmarkedContentModule.create(:content_module => create(:html_module), :name => "Bookmark!").should be_valid  
      BookmarkedContentModule.create(:content_module => create(:html_module), :name => "Bookmark!").should_not be_valid  
    end
    
    it "cannot bookmark the same content module twice" do
      html = create(:html_module)
      BookmarkedContentModule.create!(:content_module => html, :name => "Terms & Conditions")
      duplicate = BookmarkedContentModule.new(:content_module => html, :name => "Terms & Conditions")
      duplicate.should_not be_valid
      duplicate.errors[:content_module_id].first.should == "has already been bookmarked."
    end
  end
  
  describe "knowing whether it can be added to a page" do
    before(:each) do
      @page = create(:page_with_parent)
      
      @petition = create(:petition_module)
      @petition_bookmark = BookmarkedContentModule.create!(:content_module => @petition, :name => "Petition Bookmark")
      
      @taf = create(:tell_a_friend_module)
      @taf_bookmark = BookmarkedContentModule.create!(:content_module => @taf, :name => "TAF Bookmark")
       
      @html = create(:html_module)
      @html_bookmark = BookmarkedContentModule.create!(:content_module => @html, :name => "HTML Bookmark")
    end
    
    it "cannot be added to an inappropriate layout container" do
      @petition_bookmark.can_be_added_to?(@page, :sidebar).should be true
      @petition_bookmark.can_be_added_to?(@page, :main_content).should be false
    end
    
    it "cannot be added to the same page twice" do
      @html_bookmark.can_be_added_to?(@page, :main_content).should be true
      ContentModuleLink.create!(:content_module => @html, :page => @page)
      @page.reload
      @html_bookmark.can_be_added_to?(@page, :main_content).should be false
    end
    
    it "will not allow two asks to be added to the same page" do
      @petition_bookmark.can_be_added_to?(@page, :sidebar).should be true
      ContentModuleLink.create!(:content_module => @petition, :page => @page)
      @page.reload
      @petition_bookmark.can_be_added_to?(@page, :sidebar).should be false
    end
    
    it "will not allow two tell-a-friends to be added to the same page" do
      @taf_bookmark.can_be_added_to?(@page, :main_content).should be true
      ContentModuleLink.create!(:content_module => @taf, :page => @page)
      @page.reload      
      @taf_bookmark.can_be_added_to?(@page, :main_content).should be false
    end
  end
end
