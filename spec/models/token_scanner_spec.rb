#encoding: UTF-8
require File.expand_path(File.dirname(__FILE__) + "../../spec_helper")

describe TokenScanner do

  describe '#next_chunk_to_end_of_match' do

    def next_chunk(email_body)
      TokenScanner.new(email_body).send(:next_chunk_to_end_of_match, Email::URL_REGEX_HTML, SendgridTokenReplacement::TOKENS_REGEX)
    end

    def scan_next_chunk(token_scanner)
      token_scanner.send(:next_chunk_to_end_of_match, Email::URL_REGEX_HTML, SendgridTokenReplacement::TOKENS_REGEX)
    end

    it "should return remaining text if token not found" do
      email_body = 'there is no token'
      html = next_chunk(email_body)
      html.should == 'there is no token'

      email_body = 'after this{not a real token}'
      html = next_chunk(email_body)
      html.should == 'after this{not a real token}'
    end

    it "should return chunks split at the end of tokens" do
      email_body = 'before{FIRST_TOKEN|default1} more text {SECOND_TOKEN|Def2}{THIRD_TOKEN|my default} after'
      token_scanner = TokenScanner.new(email_body)
      html = scan_next_chunk(token_scanner)
      html.should == 'before{FIRST_TOKEN|default1}'

      html = scan_next_chunk(token_scanner)
      html.should == ' more text {SECOND_TOKEN|Def2}'

      html = scan_next_chunk(token_scanner)
      html.should == '{THIRD_TOKEN|my default}'

      html = scan_next_chunk(token_scanner)
      html.should == ' after'
    end

    it "should add tracking hash to links" do
      email_body = 'before<a href="http://getup.org.au/donate">donate</a>after'
      token_scanner = TokenScanner.new(email_body)
      html = scan_next_chunk(token_scanner)
      html.should == 'before<a href="http://getup.org.au/donate?t={TRACKING_HASH|NOT_AVAILABLE}">donate</a>after'
    end

    it "should add tracking hash to links with single quotes" do
      email_body = %q{ before<a href='http://getup.org.au/donate'>donate</a>after }
      token_scanner = TokenScanner.new(email_body)
      html = scan_next_chunk(token_scanner)
      html.should == %q{ before<a href='http://getup.org.au/donate?t={TRACKING_HASH|NOT_AVAILABLE}'>donate</a>after }
    end

    it "should not add tracking hash to tokens" do
      email_body =   'before{TOKEN|<a href="http://getup.org.au/donate">donate</a>}'
      token_scanner = TokenScanner.new(email_body)
      html = scan_next_chunk(token_scanner)
      html.should == 'before{TOKEN|<a href="http://getup.org.au/donate">donate</a>}'

      email_body =   "{CLOSEST_EVENT|<a href=\"http://somewhere.com\">here</a>}"
      token_scanner = TokenScanner.new(email_body)
      html = scan_next_chunk(token_scanner)
      html.should == "{CLOSEST_EVENT|<a href=\"http://somewhere.com\">here</a>}"
    end
  end

  describe '#add_tracking_hash_to_links' do

    def add_hash_to_links(email_body)
      TokenScanner.new(email_body).add_tracking_hash_to_links(Email::URL_REGEX_HTML, SendgridTokenReplacement::TOKENS_REGEX)
    end

    it "should handle blank strings" do
      html = add_hash_to_links('')
      html.should == ''
    end

    it 'should handle unicode characters' do
      email_body = 'Hello, {NAME|Friend} hello – world {NAME|Friends}'
      html = add_hash_to_links(email_body)
      html.should == 'Hello, {NAME|Friend} hello – world {NAME|Friends}'
    end

    it "should not add tracking tokens to non-markup" do
      email_body = '<a href="https://www.facebook.com/sharer.php?u=https://www.getup.org.au/redirect">https://www.facebook.com/sharer.php?u=https://www.getup.org.au/redirect</a></b> "a quote here"'
      html = add_hash_to_links(email_body)
      html.should == '<a href="https://www.facebook.com/sharer.php?u=https://www.getup.org.au/redirect&t={TRACKING_HASH|NOT_AVAILABLE}">https://www.facebook.com/sharer.php?u=https://www.getup.org.au/redirect</a></b> "a quote here"'
    end

    context 'html' do
      it "should handle multiple tokens and curly braces in text" do
        email_body = "Dear Friend, {CLOSEST_EVENT|<a href=\"http://first.com\">here</a>} Click on one of these links for more info: {First} {Second|Friend} {Third} <a href=\"https://real-link.com/index.jsp\">more info</a> {CLOSEST_EVENT|<a href=\"http://last.com\">here</a>} From the GetUp! team."
        html = add_hash_to_links(email_body)

        html.should == "Dear Friend, {CLOSEST_EVENT|<a href=\"http://first.com\">here</a>} Click on one of these links for more info: {First} {Second|Friend} {Third} <a href=\"https://real-link.com/index.jsp?t={TRACKING_HASH|NOT_AVAILABLE}\">more info</a> {CLOSEST_EVENT|<a href=\"http://last.com\">here</a>} From the GetUp! team."
      end
    end

    context 'plain text' do
      it "should not add hash to links in plain text" do
        email_body = "Pls click on this link: http://somewhere.com"
        text = add_hash_to_links(email_body)
        text.should == "Pls click on this link: http://somewhere.com"
      end

      it "should handle multiple tokens and curly braces in text" do
        email_body = "Dear Friend, {CLOSEST_EVENT|Click here to join: http://first.com} Click on one of these links for more info: {First} {Second|Friend} {Third} https://real-link.com/index.jsp {CLOSEST_EVENT|Check out our homepage here: http://last.com} From the GetUp! team."
        text = add_hash_to_links(email_body)
        text.should == "Dear Friend, {CLOSEST_EVENT|Click here to join: http://first.com} Click on one of these links for more info: {First} {Second|Friend} {Third} https://real-link.com/index.jsp {CLOSEST_EVENT|Check out our homepage here: http://last.com} From the GetUp! team."
      end
    end
  end
end
