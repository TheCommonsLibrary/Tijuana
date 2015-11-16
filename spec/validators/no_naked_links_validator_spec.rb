require File.expand_path(File.dirname(__FILE__) + "../../spec_helper")

describe NoNakedLinksValidator do

  def error_message(original_url, url, name)
    "contains naked link to '#{original_url}'. It should be enclosed in an anchor tag such as <a href=\"#{url}\">#{name}</a>"
  end
  
  before(:each) do
    @validator = NoNakedLinksValidator.new(attributes: [:attr])
    @content_module = double('model')
    @mocked_errors = double('errors')
    @content_module.stub("errors").and_return(@mocked_errors)
  end

  describe "validate each" do
    it "should add an error if a naked link starting with 'www' is present" do
      text = 'www.google.com'
      @mocked_errors.should_receive(:add).with(:attr, error_message(text, "http://www.google.com", "Google"))
      @validator.validate_each(@content_module, :attr, text)
    end

    it "should add an error if a naked link starting with 'http' is present" do
      text = 'http://google.com'
      @mocked_errors.should_receive(:add).with(:attr, error_message(text, "http://google.com", "Google"))
      @validator.validate_each(@content_module, :attr, text)
    end

    it "should NOT add an error if a naked link starting with 'http' is in a merge tag" do
      text = "{MERGE:hpd_amounts(email.id,'http://localhost:3000/campaigns/test-hpd-spread/test-page/test-page')|}"
      @mocked_errors.should_not_receive(:add)
      @validator.validate_each(@content_module, :attr, text)
    end

    it "should NOT add an error if a naked link starting with 'http' is in a style block" do
      text = "<style type='text/css'>span {background-image: url('http://localhost:3000/campaigns');}</style>"
      @mocked_errors.should_not_receive(:add)
      @validator.validate_each(@content_module, :attr, text)
    end

    it "should add an error if a naked link starting with 'https' is present" do
      text = 'https://google.com'
      @mocked_errors.should_receive(:add).with(:attr, error_message(text, "https://google.com", "Google"))
      @validator.validate_each(@content_module, :attr, text)
    end

    it "should add multiple errors if multiple naked links are present" do
      text = 'Really, http://google.com is a link that goes to www.google.com'
      @mocked_errors.should_receive(:add).with(:attr, error_message("http://google.com", "http://google.com", "Google"))
      @mocked_errors.should_receive(:add).with(:attr, error_message("www.google.com", "http://www.google.com", "Google"))
      @validator.validate_each(@content_module, :attr, text)
    end

    it "should not have any errors if no naked link is present in random text" do
      text = 'Here is some text that does not look like a link at all.'
      @mocked_errors.should_not_receive(:add)
      @validator.validate_each(@content_module, :attr, text)
    end

    it "should not have any errors if no naked link is present" do
      text = '<a href="http://www.google.com">http://www.google.com</a>'
      @mocked_errors.should_not_receive(:add)
      @validator.validate_each(@content_module, :attr, text)
    end

    it "should not have any errors if a valid img tag is present" do
      text = '<img src="https://www.google.com/image.jpg" />'
      @mocked_errors.should_not_receive(:add)
      @validator.validate_each(@content_module, :attr, text)
    end

    it "should add an error if a naked link is present, even if valid link is present elsewhere." do
      text = '<div>www.google.com.au</div><a href="http://www.google.com.au">www.google.com.au</a>'
      @mocked_errors.should_receive(:add).with(:attr, error_message("www.google.com.au", "http://www.google.com.au", "Google"))
      @validator.validate_each(@content_module, :attr, text)
    end
  end
end
