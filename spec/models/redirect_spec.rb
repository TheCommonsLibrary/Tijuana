require File.expand_path(File.dirname(__FILE__) + "../../spec_helper")

describe Redirect do
  context "page" do
    
    it 'should strip whitespace from ends of target url' do
      create(:redirect_path, :target => " http://othersite.com/whats-happening ").target.should == "http://othersite.com/whats-happening"
    end

    describe "validations" do
      it "should require an alias path between 2 and 128 characters" do
        build(:redirect_no_alias, :alias_path => "whats-happening").should be_valid
        build(:redirect_no_alias, :alias_path => "42").should be_valid
        build(:redirect_no_alias, :alias_path => "x" * 128).should be_valid
        build(:redirect_no_alias, :alias_path => "x").should_not be_valid
        build(:redirect_no_alias, :alias_path => "x" * 129).should_not be_valid
      end

      it "should require alias to contain lowercase letters, numbers, underscores, exclamation marks and hyphens only" do
        build(:redirect_no_alias, :alias_path => "my-alias-123").should be_valid
        build(:redirect_no_alias, :alias_path => "with_underscore").should be_valid
        build(:redirect_no_alias, :alias_path => "exclamation!").should be_valid
        build(:redirect_no_alias, :alias_path => "Uppercase").should_not be_valid
        build(:redirect_no_alias, :alias_path => "/something/else").should_not be_valid
        build(:redirect_no_alias, :alias_path => "broken&urls?").should_not be_valid
        build(:redirect_no_alias, :alias_path => "with spaces").should_not be_valid
      end

      it "should require an alias path between 2 and 128 characters" do
        build(:redirect_no_alias, :alias_domain => "whats-happening").should be_valid
        build(:redirect_no_alias, :alias_domain => "42").should be_valid
        build(:redirect_no_alias, :alias_domain => "x" * 128).should be_valid
        build(:redirect_no_alias, :alias_domain => "x").should_not be_valid
        build(:redirect_no_alias, :alias_domain => "x" * 129).should_not be_valid
      end

      it "should require alias to contain lowercase letters, numbers, hyphens and full stops only" do
        build(:redirect_no_alias, :alias_domain => "my-alias-123").should be_valid
        build(:redirect_no_alias, :alias_domain => "Uppercase").should_not be_valid
        build(:redirect_no_alias, :alias_domain => "/something/else").should_not be_valid
        build(:redirect_no_alias, :alias_domain => "broken&urls?").should_not be_valid
        build(:redirect_no_alias, :alias_domain => "with spaces").should_not be_valid
        build(:redirect_no_alias, :alias_domain => "test.domain.com.au").should be_valid
      end

      it "should require a target between 1 and 1024 characters" do
        build(:redirect_path, :target => "http://www.getup.org.au").should be_valid
        build(:redirect_path, :target => "/").should be_valid
        build(:redirect_path, :target => "x" * 1024).should be_valid
        build(:redirect_path, :target => "").should_not be_valid
        build(:redirect_path, :target => "x" * 1025).should_not be_valid
      end
      
      it 'should validate that target url is a valid url' do
        build(:redirect_path, :target => "http://www.getup.org.au/something with spaces").should_not be_valid
      end
      
      it 'should not allow target to include t= parameter' do
        build(:redirect_path, :target => "http://www.getup.org.au?t=sdf324x").should_not be_valid
        build(:redirect_path, :target => "http://www.getup.org.au?t=").should_not be_valid
        build(:redirect_path, :target => "http://www.getup.org.au/dunks-page?foo=bar&t=FTW").should_not be_valid
      end
    end
  end

  describe '#as_url' do
    it 'should return the domain alias' do
      redirect = Redirect.new(alias_domain: 'test.org.au', target: 'http://test.com')
      redirect.as_url('http://', 'test.bz').should == 'http://test.org.au'
    end

    it 'should return the url from alias_path' do
      redirect = Redirect.new(alias_path: 'test', target: 'http://test.com')
      redirect.as_url('http://', 'test.bz').should == 'http://test.bz/test'
    end
  end
  
  it "should merge given query strings with those already on url" do
    Redirect.merge_query_string('http://test.org.au/test', 'cat=dog').should == "http://test.org.au/test?cat=dog"
    Redirect.merge_query_string('http://test.org.au?foo=bar', 'cat=dog').should == "http://test.org.au?cat=dog&foo=bar"
    Redirect.merge_query_string('http://test.org.au?foo=bar', nil).should == "http://test.org.au?foo=bar"
    Redirect.merge_query_string('http://test.org.au?foo=bar', "").should == "http://test.org.au?foo=bar"
    Redirect.merge_query_string('http://test.org.au?foo=bar', 'foo=foo').should == "http://test.org.au?foo=bar"
    Redirect.merge_query_string('http://test.org.au?', 'cat=dog').should == "http://test.org.au?cat=dog"
    Redirect.merge_query_string('http://test.org.au/', 'cat=dog').should == "http://test.org.au/?cat=dog"
    Redirect.merge_query_string('http://test.org.au/', nil).should == "http://test.org.au/"
  end
end
