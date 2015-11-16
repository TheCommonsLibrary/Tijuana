require File.expand_path(File.dirname(__FILE__) + "../../spec_helper")
include W3CValidators

describe HtmlValidator do
  describe "w3c service for Html Validation", :vcr_off => true do
    it "should check w3c service is working" do
      content_module = create(:html_module)
      value = "<p>This is the html content with missing closing anchor tag</p><a>"
      validated = HtmlValidator.validate_each(content_module, :attr, value)
      if validated
        content_module.errors[:attr].first.should == "\^line 1: end tag for \"A\" omitted, but its declaration does not permit this"
      else
        puts "Unable to run html validator test - validation service failed"
      end
    end
  end
end