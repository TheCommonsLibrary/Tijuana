require File.expand_path(File.dirname(__FILE__) + "../../spec_helper")

describe LinksLiveValidator do

  before(:each) do
    @email = create(:email)
  end

  describe "validate each" do
    it "should add an error if a URL cannot be accessed" do
      text = "<a href='http://www.gosdsdfsdfogle.com/'>Not a real website</a>"
      Net::HTTP.stub(:start).and_raise(SocketError)
      LinksLiveValidator.validate_each(@email, :body, text)
      @email.errors.messages[:body].first.should match("cannot be resolved to a valid website.")  
    end

    it "should not add an error if a link is able to be accessed" do
      text = "<a href='http://www.google.com/'>Google</a>"
      Net::HTTP.stub(:start).and_return(Net::HTTPSuccess.new('1.1', '200', 'OK'))
      LinksLiveValidator.validate_each(@email, :body, text)
      @email.errors.should be_empty

    end

    it "should only add one error if a link is unable to be parsed because of whitespace" do
      text = "<a href='http://www.    google.com/'>Google</a>"
      LinksLiveValidator.validate_each(@email, :body, text)
      @email.errors.messages.size == 1
      @email.errors.messages[:body].first.should match("is not a well formed URI")
    end

    it "should not blow up href is missing" do
      text = "<a href-'http://www.google.com/'>Google</a>"
      LinksLiveValidator.validate_each(@email, :body, text)
      @email.errors.messages[:body].should be_nil
    end

    it "should not test if a 'mailto:' link is live" do
      text = "<a href='mailto:g@g.com'>Mail to link</a>"
      LinksLiveValidator.validate_each(@email, :body, text)
      LinksLiveValidator.should_not_receive(:is_url_reachable)
      @email.errors.should be_empty
    end
  end
end
