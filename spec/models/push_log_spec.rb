require File.expand_path(File.dirname(__FILE__) + "../../spec_helper")

describe PushLog do
  it "logs the blast information as well as the exception message received" do
    email = create(:email)
    user_ids = [1,2]
    exception = Exception.new("Error sending blast. The number of recipients doesn't match the number of replacement tokens. 794 != 793")

    PushLog.log_exception(email, user_ids, exception)

    PushLog.last.message.should eql "Push: #{email.blast.push.id} - Blast: #{email.blast.id} - Email: #{email.id} - User ids: #{[user_ids].flatten.join(",")} - Exception: #{exception.message}"
  end
end
