require File.expand_path(File.dirname(__FILE__) + "../../spec_helper")

describe ThankyouEmail do
  it "delivers via actionmailer" do
    constructed_email = Object.new
    Emailer.should_receive(:thankyou_email).with("user@email.com", "the subject", "the body").and_return(constructed_email)
    constructed_email.should_receive(:deliver)
    
    page = create(:page_with_parent, :thankyou_email_subject => "the subject", :thankyou_email_text => "the body")
    user = create(:user, :email => "user@email.com")
    ThankyouEmail.new(page, user, double(ContentModule)).send!
  end
  
  describe "templated body text" do 
    it "should substitute user's first name if known" do
      page = create(:page_with_parent, :thankyou_email_text => "Dear {NAME|Friend}")
      user = create(:user, :first_name => "Jeeves")
      email = ThankyouEmail.new(page, user, create(:petition_module))
      email.send(:templated_body_text).should == "Dear Jeeves"
      user.first_name = ""
      email.send(:templated_body_text).should == "Dear Friend"
    end

    it "should substitute ask module text" do
      page = create(:page_with_parent, :thankyou_email_text => "Jibber {ASK_MODULE_TEXT} Jabber")
      user = create(:user)
      content_module = double(ContentModule)
      content_module.stub(ask_module_text: 'Joomla')
      email = ThankyouEmail.new(page, user, content_module)
      email.send(:templated_body_text).should == "Jibber Joomla Jabber"
    end

    it "should substitute ask module text with blank if modules does not respond to thankyou_email_snippet" do
      page = create(:page_with_parent, :thankyou_email_text => "Jibber {ASK_MODULE_TEXT} Jabber")
      user = create(:user)
      content_module = double(ContentModule)
      content_module.should_not respond_to(:ask_module_text)
      email = ThankyouEmail.new(page, user, content_module)
      email.send(:templated_body_text).should == "Jibber  Jabber"
    end
  end
end