require File.join(File.dirname(__FILE__), '../spec_helper')
require File.join(File.dirname(__FILE__), '../../lib/exception_notifier_rescue_and_mail_tech')

describe ExceptionNotifier do
  describe '#rescue_and_mail_tech' do
    before :each do
      ActionMailer::Base.deliveries = nil
    end

    after :each do
      ActionMailer::Base.deliveries = nil
    end

    it "doesn't email for exceptions we want to ignore" do
      error_to_ignore = IGNORED_EXCEPTIONS.first.constantize
      ExceptionNotifier.rescue_and_mail_tech { raise error_to_ignore }
      ActionMailer::Base.should have(0).deliveries
    end

    context 'with env variable' do
      it 'should email tech' do
        ExceptionNotifier.rescue_and_mail_tech({test_env: 'I am a test env'}) { raise "hell" }
        ActionMailer::Base.should have(1).deliveries
      end

      it 'should rescue when an exception is thrown from the mailer' do
        mock_mail = double()
        mock_mail.stub(:deliver) {raise Exception}
        ExceptionNotifier.should_receive(:notify_exception).and_return(mock_mail)
        expect {ExceptionNotifier.rescue_and_mail_tech({test_env: 'I am a test env'}) { raise "hell" }}.not_to raise_exception
      end

      it 'should not contain sessions section when disable_session_section set to true' do
        ExceptionNotifier.rescue_and_mail_tech({test_env: 'I am a test env'}, true) { raise "hell" }
        ActionMailer::Base.should have(1).deliveries
        ActionMailer::Base.deliveries.first.body.should_not include 'Session:'
      end

      it 'should include sessions section when disable_session_section set to false' do
        ExceptionNotifier.rescue_and_mail_tech({test_env: 'I am a test env'}, false) { raise "hell" }
        ActionMailer::Base.should have(1).deliveries
        ActionMailer::Base.deliveries.first.body.should include 'Session:'
      end
    end

    context 'without env variable' do
      it 'should email tech' do
        ExceptionNotifier.rescue_and_mail_tech { raise "hell" }
        ActionMailer::Base.should have(1).deliveries
      end

      it 'should rescue when an exception is thrown from the mailer' do
        mock_mail = double()
        mock_mail.stub(:deliver) { raise "hell" }
        ExceptionNotifier.should_receive(:notify_exception).and_return(mock_mail)
        expect {ExceptionNotifier.rescue_and_mail_tech { Exception.throw("I'm an exception") }}.not_to raise_exception
      end
    end
  end
end
