require File.expand_path(File.dirname(__FILE__) + "../../spec_helper")
describe "Exception notification" do

  before(:each) do
    ActionMailer::Base.deliveries = []
  end

  describe "ExceptionNotifer reports handled exceptions" do
    it "should send email on error" do
      begin
        raise "An Error"
      rescue => e
        ExceptionNotifier.notify_exception(e)
      end
      ActionMailer::Base.should have(1).deliveries
    end
  end

  describe "A random, unhandled error occurs in the application" do
    it "ExceptionNotifier should catch error and send email, and app should return 500" do
      expect { get '/admin/raise_error/blowup' }.to raise_exception(/As expected, we have thrown an exception/)
      ActionMailer::Base.should have(1).deliveries
    end
  end
end


