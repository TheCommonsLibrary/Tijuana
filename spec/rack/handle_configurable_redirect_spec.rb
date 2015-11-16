require File.expand_path(File.dirname(__FILE__) + "../../spec_helper")

describe HandleConfigurableRedirect do
  before(:each) do
    @app = double()
    @middleware = HandleConfigurableRedirect.new(@app) 
  end
  
  it "should not lookup when on canonical URI and not top level request" do
    #canonical URI configured in constants
    @middleware.should_not_receive(:check_for_redirect)
    @app.should_receive(:call)
    @middleware.call("SERVER_NAME" => 'localhost', "PATH_INFO" => "/important/something", "QUERY_STRING" => "", 'REQUEST_METHOD' => 'GET')
  end

  it "swallows errors from failed query string parsing" do
    query_string = "t=dXNlcmlkPTM1Njc3NyxlbWFpbGlkPTgxOQ%3D%3"
    expect{
      @middleware.send(:safe_parse_nested_query, query_string)
    }.not_to raise_error
  end

  context 'with path aliases' do
    without_transactional_fixtures do
      it 'should send email on exception and continue redirect' do
        with_push_table do
          user = create(:user)
          ActionMailer::Base.deliveries = nil
          email = create(:email)
          token = EmailTrackingToken.encode(user.id, email.id)
          Redirect.create!(alias_path: 'test', target: 'http://www.test.com')
          @app.should_not_receive(:call)
          UserActivityEvent.should_receive(:email_clicked!).and_raise(Exception)
          result = @middleware.call('SERVER_NAME' => 'localhost', 'PATH_INFO' => '/test', 'QUERY_STRING' => "t=#{token}", 'REQUEST_METHOD' => 'GET')
          result.first.should == 302
          ActionMailer::Base.should have(1).deliveries
        end
      end

      it 'should swallow an exception from the exception notifier' do
        with_push_table do
          user = create(:user)
          email = create(:email)
          token = EmailTrackingToken.encode(user.id, email.id)
          mock_mail = double()
          Redirect.create!(alias_path: 'test', target: 'http://www.test.com')

          ActionMailer::Base.deliveries = nil

          mock_mail.stub(:deliver) {throw Exception}
          UserActivityEvent.should_receive(:email_clicked!).and_raise(Exception)
          ExceptionNotifier.should_receive(:notify_exception).and_return(mock_mail)
          @app.should_not_receive(:call)

          result = @middleware.call('SERVER_NAME' => 'localhost', 'PATH_INFO' => '/test', 'QUERY_STRING' => "t=#{token}", 'REQUEST_METHOD' => 'GET')

          result.first.should == 302
          ActionMailer::Base.should have(0).deliveries
        end
      end

      it 'should not track an email click if token is present on post request' do
        with_push_table do
          user = create(:user)
          campaign = create(:campaign)
          push = create(:push, campaign: campaign)
          blast = create(:blast, push: push)
          email = create(:email, blast: blast)
          token = EmailTrackingToken.encode(user.id, email.id)
          Redirect.create!(alias_path: 'test', target: 'http://www.test.com')
          @app.should_not_receive(:call)
          push.count_by_activity(:email_clicked).should eql 0
          result = @middleware.call('SERVER_NAME' => 'localhost', 'PATH_INFO' => '/test', 'QUERY_STRING' => "t=#{token}", 'REQUEST_METHOD' => 'POST')
          result.first.should == 302
          push.count_by_activity(:email_clicked).should eql 0
        end
      end

      it 'should track an email click if token is present on get request' do
        with_push_table do
          user = create(:user)
          campaign = create(:campaign)
          push = create(:push, campaign: campaign)
          blast = create(:blast, push: push)
          email = create(:email, blast: blast)
          token = EmailTrackingToken.encode(user.id, email.id)
          Redirect.create!(alias_path: 'test', target: 'http://www.test.com')
          @app.should_not_receive(:call)
          push.count_by_activity(:email_clicked).should eql 0
          result = @middleware.call('SERVER_NAME' => 'localhost', 'PATH_INFO' => '/test', 'QUERY_STRING' => "t=#{token}", 'REQUEST_METHOD' => 'GET')
          push.count_by_activity(:email_clicked).should eql 1
          result.first.should == 302
        end
      end
    end

    it 'should not track an email click if token not present' do
      Redirect.create!(alias_path: 'test', target: 'http://www.test.com')
      @app.should_not_receive(:call)
      Push.any_instance.should_not_receive(:count_by_activity)
      result = @middleware.call('SERVER_NAME' => 'localhost', 'PATH_INFO' => '/test', 'QUERY_STRING' => "", 'REQUEST_METHOD' => 'GET')
      result.first.should == 302
    end

    it 'should not track an email click if token is invalid' do
      Redirect.create!(alias_path: 'test', target: 'http://www.test.com')
      @app.should_not_receive(:call)
      Push.any_instance.should_not_receive(:count_by_activity)
      result = @middleware.call('SERVER_NAME' => 'localhost', 'PATH_INFO' => '/test', 'QUERY_STRING' => "t=1234", 'REQUEST_METHOD' => 'GET')
      result.first.should == 302
    end

    it "redirect if alias has been configured" do
      Redirect.create!(:alias_path => "important", :target => "http://www.test.com")
      @app.should_not_receive(:call)
      @middleware.call("SERVER_NAME" => 'localhost', "PATH_INFO" => "/important", "QUERY_STRING" => "", 'REQUEST_METHOD' => 'GET').should == [302, {"Location" => "http://www.test.com"}, ["Redirecting..."]]
    end

    it "should preserve params (e.g. email tracking data) across the redirect" do
      Redirect.create!(:alias_path => "important", :target => "http://www.test.com")
      @app.should_not_receive(:call)
      @middleware.call("SERVER_NAME" => 'localhost', "PATH_INFO" => "/important", "QUERY_STRING" => "t=1234&foo=bar", 'REQUEST_METHOD' => 'GET').should == [302, {"Location" => "http://www.test.com?foo=bar&t=1234"}, ["Redirecting..."]]
    end

    it "should not redirect if alias is not found" do
      @app.should_receive(:call)
      @middleware.call("SERVER_NAME" => 'localhost', "PATH_INFO" => "/not-a-redirect").should be_nil
    end

    it "should not redirect if alias forms part of another URL" do
      Redirect.create!(:alias_path => "important", :target => "http://www.test.com")
      @app.should_receive(:call).twice
      @middleware.call("SERVER_NAME" => 'localhost', "PATH_INFO" => "/not/important").should be_nil
      @middleware.call("SERVER_NAME" => 'localhost', "PATH_INFO" => "/important/really").should be_nil
    end
  end

  context 'with alias domains' do
    without_transactional_fixtures do
      it 'should send email on exception and continue redirect' do
        with_push_table do
          user = create(:user)
          ActionMailer::Base.deliveries = nil
          email = create(:email)
          token = EmailTrackingToken.encode(user.id, email.id)
          Redirect.create!(alias_domain: 'differentdomain.com', target: 'http://www.test.com')
          @app.should_not_receive(:call)
          UserActivityEvent.should_receive(:email_clicked!).and_raise(Exception)
          result = @middleware.call('SERVER_NAME' => 'differentdomain.com', 'PATH_INFO' => '/test', 'QUERY_STRING' => "t=#{token}", 'REQUEST_METHOD' => 'GET')
          result.first.should == 302
          ActionMailer::Base.should have(1).deliveries
        end
      end

      it 'should swallow an exception from the exception notifier' do
        with_push_table do
          user = create(:user)
          email = create(:email)
          token = EmailTrackingToken.encode(user.id, email.id)
          mock_mail = double()
          Redirect.create!(alias_domain: 'differentdomain.com', target: 'http://www.test.com')

          ActionMailer::Base.deliveries = nil

          mock_mail.stub(:deliver) {throw Exception}
          UserActivityEvent.should_receive(:email_clicked!).and_raise(Exception)
          ExceptionNotifier.should_receive(:notify_exception).and_return(mock_mail)
          @app.should_not_receive(:call)

          result = @middleware.call('SERVER_NAME' => 'differentdomain.com', 'PATH_INFO' => '/test', 'QUERY_STRING' => "t=#{token}", 'REQUEST_METHOD' => 'GET')

          result.first.should == 302
          ActionMailer::Base.should have(0).deliveries
        end
      end

      it 'should not track an email click if token is present on post request' do
        with_push_table do
          user = create(:user)
          campaign = create(:campaign)
          push = create(:push, campaign: campaign)
          blast = create(:blast, push: push)
          email = create(:email, blast: blast)
          token = EmailTrackingToken.encode(user.id, email.id)
          Redirect.create!(alias_domain: 'differentdomain.com', target: 'http://www.test.com')
          @app.should_not_receive(:call)
          push.count_by_activity(:email_clicked).should eql 0
          result = @middleware.call('SERVER_NAME' => 'differentdomain.com', 'PATH_INFO' => '/test', 'QUERY_STRING' => "t=#{token}", 'REQUEST_METHOD' => 'POST')
          result.first.should == 302
          push.count_by_activity(:email_clicked).should eql 0
        end
      end

      it 'should track an email click if token is present on get request' do
        with_push_table do
          user = create(:user)
          campaign = create(:campaign)
          push = create(:push, campaign: campaign)
          blast = create(:blast, push: push)
          email = create(:email, blast: blast)
          token = EmailTrackingToken.encode(user.id, email.id)
          Redirect.create!(alias_domain: 'differentdomain.com', target: 'http://www.test.com')
          @app.should_not_receive(:call)
          push.count_by_activity(:email_clicked).should eql 0
          result = @middleware.call('SERVER_NAME' => 'differentdomain.com', 'PATH_INFO' => '/test', 'QUERY_STRING' => "t=#{token}", 'REQUEST_METHOD' => 'GET')
          result.first.should == 302
          push.count_by_activity(:email_clicked).should eql 1
        end
      end
    end

    it 'should not track an email click if token not present' do
      Redirect.create!(alias_domain: 'differentdomain.com', target: 'http://www.test.com')
      @app.should_not_receive(:call)
      Push.any_instance.should_not_receive(:count_by_activity)
      result = @middleware.call('SERVER_NAME' => 'differentdomain.com', 'PATH_INFO' => '/test', 'QUERY_STRING' => "", 'REQUEST_METHOD' => 'GET')
      result.first.should == 302
    end

    it 'should not track an email click if token is invalid' do
      Redirect.create!(alias_domain: 'differentdomain.com', target: 'http://www.test.com')
      @app.should_not_receive(:call)
      Push.any_instance.should_not_receive(:count_by_activity)
      result = @middleware.call('SERVER_NAME' => 'differentdomain.com', 'PATH_INFO' => '/test', 'QUERY_STRING' => "t=1234", 'REQUEST_METHOD' => 'GET')
      result.first.should == 302
    end

    it "should redirect from alias domain" do
      Redirect.create!(:alias_domain => "differentdomain.com", :target => "http://google.com")
      @app.should_not_receive(:call)
      @middleware.call("SERVER_NAME" => "differentdomain.com", "QUERY_STRING" => "", 'REQUEST_METHOD' => 'GET').should == [302, {"Location" => "http://google.com"}, ["Redirecting..."]]
    end

    it "should not redirect for cloaked domains" do
      #appconstants defines communityrun cloaked domain
      Redirect.create!(:alias_domain => "differentdomain.com", :target => "http://google.com")
      @app.should_receive(:call)
      @middleware.call("SERVER_NAME" => "content.communityrun.org", "PATH_INFO" => "take-action-now", "QUERY_STRING" => "", 'REQUEST_METHOD' => 'GET').should be_nil
    end

    it "should not redirect for canonical domain" do
      #localhost is the canonical domain for test env
      @app.should_receive(:call)
      @middleware.call("SERVER_NAME" => "localhost", "PATH_INFO" => "take-action-now", "QUERY_STRING" => "", 'REQUEST_METHOD' => 'GET').should be_nil

      Redirect.create!(:alias_domain => "localhost", :target => "http://google.com")
      @app.should_receive(:call)
      @middleware.call("SERVER_NAME" => "localhost", "PATH_INFO" => "take-action-now", "QUERY_STRING" => "", 'REQUEST_METHOD' => 'GET').should be_nil
    end
  end
end
