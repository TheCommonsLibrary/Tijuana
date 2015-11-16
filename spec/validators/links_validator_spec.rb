require File.expand_path(File.dirname(__FILE__) + "../../spec_helper")

describe LinksValidator do

  before(:each) do
    @validator = LinksValidator.new(attributes: [:attr])
    @model = double('model')
    @mocked_errors = double('errors')
    @model.stub("errors").and_return(@mocked_errors)
  end

  describe "validate each" do
    it "should add an error if a link with whitespace is present" do
      text = "<a href='http://www.googl  .com'>Google</a>"
      @mocked_errors.should_receive(:add).with(:attr, "Anchor tag: 'http://www.googl  .com' cannot have whitespace present in href attribute.")
      @validator.validate_each(@model, :attr, text)
    end

    it "should add an error if a link with trailing whitespace present" do
      text = "<a href='http://www.google.com   '>Google</a>"
      @mocked_errors.should_receive(:add).with(:attr, "Anchor tag: 'http://www.google.com   ' cannot have whitespace present in href attribute.")
      @validator.validate_each(@model, :attr, text)
    end

    it "should add an error if a link with protocol incorrect" do
      text = "<a href='ftp://www.google.com'>Google</a>"
      @mocked_errors.should_receive(:add).with(:attr, "Anchor tag: 'ftp://www.google.com' href attribute can only be 'http://', 'https://' or 'mailto:'")
      @validator.validate_each(@model, :attr, text)
    end

    it "should not add an error when there is a mail-to link inside a href attribute" do
      text = "<a href='mailto:someone@example.com?Subject=Hello%20again'>Mail to link</a>"
      @mocked_errors.should_not_receive(:add)
      @validator.validate_each(@model, :attr, text)
    end

    it "should add an error if invalid anchor tags" do
      text = "<a =href'http://www.getup.org.au/everychild-nsw\'>GetUp</a>"
      @mocked_errors.should_receive(:add).with(:attr, "Anchor tag: '<a>GetUp</a>' must have an href attribute present. If an href exists, make sure it's correctly formed eg <a href='http://www.google.com/'>Google</a>")
      @validator.validate_each(@model, :attr, text)
    end
  end
end
