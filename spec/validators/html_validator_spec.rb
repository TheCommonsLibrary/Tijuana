require File.expand_path(File.dirname(__FILE__) + "../../spec_helper")
include W3CValidators

describe HtmlValidator do
  describe "validate each" do
    before(:each) do
      @validator = double()
      MarkupValidator.stub(:new).and_return(@validator)
    end

    it "should add an errors if html content is not a valid" do
      content_module = create(:invalid_html_module)

      results = double()
      errors = ['an error']
      results.stub(:errors).and_return(errors)


      @validator.stub(:set_doctype!).with(:html4)

      @validator.should_receive(:validate_text).and_return(results)
      HtmlValidator.validate_each(content_module, :attr, content_module.content)
      content_module.errors.size.should > 0
      content_module.errors[:attr].first.should  == "^an error"
    end

    it "should return no errors if html content is valid" do
      content_module = create(:html_module)

      results =  double()
      errors = []
      results.stub(:errors).and_return(errors)

      @validator.stub(:set_doctype!).with(:html4)
      @validator.should_receive(:validate_text).and_return(results)

      HtmlValidator.validate_each(content_module, :attr, content_module.content)
      content_module.errors.size.should == 0
    end

    it "should create a valid html document from the html string provided" do
      content_module = create(:html_module)
      doc = "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01//EN\" \"http://www.w3.org/TR/html4/strict.dtd\"><html><head><title></title></head><body><div><p>Lorem ipsum dolor sit amet</p><p>Lorem ipsum dolor sit amet</p><p>Lorem ipsum dolor sit amet</p><p>Lorem ipsum dolor sit amet</p><p>Lorem ipsum dolor sit amet</p></div></body></html>\n"

      results =  double()
      errors = []
      results.stub(:errors).and_return(errors)

      @validator.stub(:set_doctype!).with(:html4)
      @validator.should_receive(:validate_text).with(doc).and_return(results)

      HtmlValidator.validate_each(content_module, :attr, content_module.content)
    end

  end
end