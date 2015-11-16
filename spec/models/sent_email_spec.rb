require 'spec_helper'

describe SentEmail do
  describe "validation" do
    before :each do
      @sent_email = create(:sent_email, subject: "A subject", body: "A body", recipient_count: 5, sql: "SQL")
    end
    it "should not save an invalid object" do
      @sent_email.subject = nil
      @sent_email.body = nil
      @sent_email.recipient_count = nil
      @sent_email.sql = nil
      @sent_email.valid?.should be false
    end
    it "should save a valid object" do
      @sent_email.valid?.should be true
    end
  end
end
