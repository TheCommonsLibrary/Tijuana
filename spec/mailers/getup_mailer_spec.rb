require File.expand_path(File.dirname(__FILE__) + "../../spec_helper")

describe 'Concreate subclasses of GetupMailer' do

  describe '#mail' do
    it "should send mail with 'from' address set from options" do
      email = Emailer.target_email('billy@bob.com', 'info@getup.org.au', nil, 'test', 'test')
      email.from.should == ['info@getup.org.au']
      email.reply_to.should be_blank
    end

    context "'from' domain is invalid" do
      before(:each) { AppConstants.stub(:invalid_from_email_domain).and_return(['yahoo.com', 'aol.com']) }

      context "email only in 'from' field" do
        it "should rewrite the 'from' address and set the reply-to address to the real from address" do
          email = Emailer.target_email('billy@bob.com', 'info@aol.com', nil, 'test', 'test')
          email.from.should == ['info@aol.com.invalid']
          email.reply_to.should == ['info@aol.com']
        end
      end

      context "name and email in 'from' field" do
        it "should rewrite the 'from' address and set 'reply-to' and leave the name in tact" do
          email = Emailer.target_email('billy@bob.com', 'Timmy Bob <info@aol.com>', nil, 'test', 'test')
          email.from.should == ['info@aol.com.invalid']
          email.header[:from].to_s.should == 'Timmy Bob <info@aol.com.invalid>'
          email.reply_to.should == ['info@aol.com']
        end
      end

    end
  end
end
