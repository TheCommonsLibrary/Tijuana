require File.expand_path(File.dirname(__FILE__) + "../../spec_helper")

describe HandleLinkShortenerRedirect do
  describe '#call' do
    before(:each) do
      @app = double()
      @middleware = HandleLinkShortenerRedirect.new(@app)
    end

    context 'when NOT a link shortener url' do
      it 'should invoke @app.call' do
        env = {
          'SERVER_NAME' => 'localhost',
          'PATH_INFO' => '/campaigns'
        }
        @app.should_receive(:call).with(env)
        @middleware.call(env)
      end
    end

    context 'when is a link shortener url' do
      context 'and valid hash' do

        without_transactional_fixtures do
          context 'with user_id, email_id and page_id' do
            it 'should redirect to page with a valid token' do
              with_push_table do
                campaign = create(:campaign, name: 'a campaign name')
                page_sequence = create(:page_sequence, campaign: campaign, name: 'a page_sequence name')
                page = create(:page, page_sequence: page_sequence, name: 'a page name')

                user = create(:user)
                email = create(:email)
                redirect_id = 0
                token = EmailTrackingToken.encode(user.id,email.id)

                hashids = Hashids.new(AppConstants.link_shortener_salt)
                hash = hashids.encode(user.id, email.id, page.id, redirect_id)
                env = {'SERVER_NAME' => 'getup.to','PATH_INFO' => "/#{hash}", 'rack.url_scheme' => 'http'}

                @app.should_not_receive(:call)
                result = @middleware.call(env)

                result.should == [302, {'Location'=>"http://localhost/campaigns/#{campaign.id}/#{page_sequence.id}/#{page.id}?t=#{token}"}, ['Redirecting...']]
              end
            end
          end

          context 'with user_id, email_id, page_id and redirect_id' do
            it 'should redirect to configurable redirect with token' do
              with_push_table do
                campaign = create(:campaign, name: 'a campaign name')
                page_sequence = create(:page_sequence, campaign: campaign, name: 'a page_sequence name')
                page = create(:page, page_sequence: page_sequence, name: 'a page name')
                redirect = create(:redirect_path, alias_path: 'test', target: 'http://www.test.com')

                user = create(:user)
                email = create(:email)
                token = EmailTrackingToken.encode(user.id,email.id)

                hashids = Hashids.new(AppConstants.link_shortener_salt)
                hash = hashids.encode(user.id, email.id, page.id, redirect.id)
                env = {'SERVER_NAME' => 'getup.to','PATH_INFO' => "/#{hash}"}

                @app.should_not_receive(:call)
                result = @middleware.call(env)

                result.should == [302, {'Location'=>"http://www.test.com?t=#{token}"}, ['Redirecting...']]
              end
            end
          end
        end

        context 'with page_id for static page' do
          it 'should redirect to the static page' do
            page_sequence = create(:static_page_sequence)
            page = create(:page, page_sequence: page_sequence)

            user_id = 0
            email_id = 0
            redirect_id = 0

            hashids = Hashids.new(AppConstants.link_shortener_salt)
            hash = hashids.encode(user_id, email_id, page.id, redirect_id)
            env = {'SERVER_NAME' => 'getup.to','PATH_INFO' => "/#{hash}", 'rack.url_scheme' => 'http'}

            @app.should_not_receive(:call)
            result = @middleware.call(env)

            result.should == [302, {'Location'=>"http://localhost/#{page_sequence.id}/#{page.id}"}, ['Redirecting...']]
          end

          it 'should redirect to the static page from www' do
            page_sequence = create(:static_page_sequence)
            page = create(:page, page_sequence: page_sequence)

            user_id = 0
            email_id = 0
            redirect_id = 0

            hashids = Hashids.new(AppConstants.link_shortener_salt)
            hash = hashids.encode(user_id, email_id, page.id, redirect_id)
            env = {'SERVER_NAME' => 'www.getup.to','PATH_INFO' => "/#{hash}", 'rack.url_scheme' => 'http'}

            @app.should_not_receive(:call)
            result = @middleware.call(env)

            result.should == [302, {'Location'=>"http://localhost/#{page_sequence.id}/#{page.id}"}, ['Redirecting...']]
          end
        end



        context 'with user_id and redirect_id' do
          it 'should redirect to configurable redirect with token' do
            redirect = create(:redirect_no_alias, alias_domain: 'www.example.com', target: 'http://www.test.com')

            user_id = 1
            email_id = 0
            page_id = 0

            hashids = Hashids.new(AppConstants.link_shortener_salt)
            hash = hashids.encode(user_id, email_id, page_id, redirect.id)
            env = {'SERVER_NAME' => 'getup.to','PATH_INFO' => "/#{hash}"}

            @app.should_not_receive(:call)
            result = @middleware.call(env)

            result.should == [302, {'Location'=>'http://www.test.com'}, ['Redirecting...']]
          end
        end
      end

      context 'not a valid hash' do
        it 'should direct to homepage' do
          invalid_hash = "wjd72sqklfdwxf1"

          env = {'SERVER_NAME' => 'getup.to','PATH_INFO' => "/#{invalid_hash}", 'rack.url_scheme' => 'http'}

          @app.should_not_receive(:call)
          result = @middleware.call(env)

          result.should == [302, {'Location'=>'http://localhost'}, ['Redirecting...']]
        end
      end
    end
  end
end
