require File.expand_path(File.dirname(__FILE__) + "../../spec_helper")

describe PagesHelper do
  describe "#take_action_path" do
    it "should return take_action_page_path if request comes from default domain" do
      campaign = create(:campaign)
      page_sequence = create(:page_sequence, :campaign => campaign)
      page = create(:page, :page_sequence => page_sequence)
      helper.take_action_path(campaign, page_sequence, page).should == take_action_page_path(campaign.friendly_id, page_sequence.friendly_id, page.friendly_id)
    end

    it "should return take_action_cloaked_page_path if request comes from cloaked domain" do
      campaign = create(:campaign, :name => "community-run-content")
      page_sequence = create(:page_sequence, :campaign => campaign)
      page = create(:page, :page_sequence => page_sequence)
      helper.request.stub(:host).and_return("content.communityrun.org")
      helper.take_action_path(campaign, page_sequence, page).should == take_action_cloaked_page_path(page_sequence.friendly_id, page.friendly_id)
    end
  end

  describe '#generate_short_link' do
    context 'no redirect configured' do
      it 'should return the link shortened url when no token' do
        campaign = create(:campaign)
        page_sequence = create(:page_sequence, :campaign => campaign)
        page = create(:page, :page_sequence => page_sequence)
        user_id, email_id, redirect_id = 0,0,0
        hashids = Hashids.new(AppConstants.link_shortener_salt)
        hash = hashids.encode(user_id,email_id,page.id,redirect_id)
        helper.generate_short_link(page, nil).should == "http://getup.to/#{hash}"
      end

      without_transactional_fixtures do
        it 'should return the link shortened url when valid token' do
          with_push_table do
            campaign = create(:campaign)
            user = create(:user)
            email = create(:email)
            token = EmailTrackingToken.encode(user.id, email.id)
            page_sequence = create(:page_sequence, :campaign => campaign)
            page = create(:page, :page_sequence => page_sequence)
            redirect_id = 0
            hashids = Hashids.new(AppConstants.link_shortener_salt)
            hash = hashids.encode(user.id,email.id,page.id,redirect_id)
            helper.generate_short_link(page, token).should == "http://getup.to/#{hash}"
          end
        end
      end

      it 'should return the link shortened url when invalid token' do
        campaign = create(:campaign)
        user = create(:user)
        token = EmailTrackingToken.encode(user.id, -1)
        page_sequence = create(:page_sequence, :campaign => campaign)
        page = create(:page, :page_sequence => page_sequence)

        user_id, email_id, redirect_id = 0,0,0
        hashids = Hashids.new(AppConstants.link_shortener_salt)
        hash = hashids.encode(user_id,email_id,page.id,redirect_id)

        helper.generate_short_link(page, token).should == "http://getup.to/#{hash}"
      end
    end

    context 'redirect configured against the page' do
      context 'with alias_path' do
        it 'should return the link shortened url from alias_path' do
          campaign = create(:campaign)
          page_sequence = create(:page_sequence, :campaign => campaign)
          page = create(:page, :page_sequence => page_sequence)
          redirect = Redirect.create! alias_path: 'test', target: 'http://test.host/campaigns/dummy-campaign-name/dummy-page-sequence-name/unnamed-page'
          user_id, email_id = 0,0
          hashids = Hashids.new(AppConstants.link_shortener_salt)
          hash = hashids.encode(user_id,email_id,page.id,redirect.id)
          helper.generate_short_link(page, nil).should == "http://getup.to/#{hash}"
        end

        without_transactional_fixtures do
          it 'should return the link shortened url when valid token' do
            with_push_table do
              campaign = create(:campaign)
              user = create(:user)
              email = create(:email)
              token = EmailTrackingToken.encode(user.id, email.id)
              page_sequence = create(:page_sequence, :campaign => campaign)
              page = create(:page, :page_sequence => page_sequence)
              redirect = Redirect.create! alias_path: 'test', target: 'http://test.host/campaigns/dummy-campaign-name/dummy-page-sequence-name/unnamed-page'

              hashids = Hashids.new(AppConstants.link_shortener_salt)
              hash = hashids.encode(user.id,email.id,page.id,redirect.id)

              helper.generate_short_link(page, token).should == "http://getup.to/#{hash}"
            end
          end
        end

        it 'should return the link shortened url when invalid token' do
          campaign = create(:campaign)
          user = create(:user)
          token = EmailTrackingToken.encode(user.id, -1)
          page_sequence = create(:page_sequence, :campaign => campaign)
          page = create(:page, :page_sequence => page_sequence)
          redirect = Redirect.create! alias_path: 'test', target: 'http://test.host/campaigns/dummy-campaign-name/dummy-page-sequence-name/unnamed-page'

          user_id, email_id = 0,0
          hashids = Hashids.new(AppConstants.link_shortener_salt)
          hash = hashids.encode(user_id,email_id,page.id,redirect.id)

          helper.generate_short_link(page, token).should == "http://getup.to/#{hash}"
        end
      end

      context ' with domain alias' do
        it 'should return the link shortened url' do
          campaign = create(:campaign)
          page_sequence = create(:page_sequence, :campaign => campaign)
          page = create(:page, :page_sequence => page_sequence)
          redirect = Redirect.create! alias_domain: 'test.org.au', target: 'http://test.host/campaigns/dummy-campaign-name/dummy-page-sequence-name/unnamed-page'

          user_id, email_id = 0,0
          hashids = Hashids.new(AppConstants.link_shortener_salt)
          hash = hashids.encode(user_id,email_id,page.id,redirect.id)

          helper.generate_short_link(page, nil).should == "http://getup.to/#{hash}"
        end

        without_transactional_fixtures do
          it 'should return the link shortened url when valid token' do
            with_push_table do
              campaign = create(:campaign)
              user = create(:user)
              email = create(:email)
              token = EmailTrackingToken.encode(user.id, email.id)
              page_sequence = create(:page_sequence, :campaign => campaign)
              page = create(:page, :page_sequence => page_sequence)
              redirect = Redirect.create! alias_domain: 'test.org.au', target: 'http://test.host/campaigns/dummy-campaign-name/dummy-page-sequence-name/unnamed-page'

              hashids = Hashids.new(AppConstants.link_shortener_salt)
              hash = hashids.encode(user.id,email.id,page.id,redirect.id)

              helper.generate_short_link(page, token).should == "http://getup.to/#{hash}"
            end
          end
        end

        it 'should return the link shortened url when invalid token' do
          campaign = create(:campaign)
          user = create(:user)
          token = EmailTrackingToken.encode(user.id, -1)
          page_sequence = create(:page_sequence, :campaign => campaign)
          page = create(:page, :page_sequence => page_sequence)
          redirect = Redirect.create! alias_domain: 'test.org.au', target: 'http://test.host/campaigns/dummy-campaign-name/dummy-page-sequence-name/unnamed-page'

          user_id, email_id = 0,0
          hashids = Hashids.new(AppConstants.link_shortener_salt)
          hash = hashids.encode(user_id,email_id,page.id,redirect.id)

          helper.generate_short_link(page, token).should == "http://getup.to/#{hash}"
        end
      end
    end

    context 'redirect configured against the page sequence' do
      context 'with alias path' do
        it 'should return the link shortened url' do
          campaign = create(:campaign)
          page_sequence = create(:page_sequence, :campaign => campaign)
          page = create(:page, :page_sequence => page_sequence)
          redirect = Redirect.create! alias_path: 'test', target: 'http://test.host/campaigns/dummy-campaign-name/dummy-page-sequence-name'

          user_id, email_id = 0,0
          hashids = Hashids.new(AppConstants.link_shortener_salt)
          hash = hashids.encode(user_id,email_id,page.id,redirect.id)

          helper.generate_short_link(page, nil).should == "http://getup.to/#{hash}"
        end

        without_transactional_fixtures do
          it 'should return the link shortened url when valid token' do
            with_push_table do
              campaign = create(:campaign)
              user = create(:user)
              email = create(:email)
              token = EmailTrackingToken.encode(user.id, email.id)
              page_sequence = create(:page_sequence, :campaign => campaign)
              page = create(:page, :page_sequence => page_sequence)
              redirect = Redirect.create! alias_path: 'test', target: 'http://test.host/campaigns/dummy-campaign-name/dummy-page-sequence-name'

              hashids = Hashids.new(AppConstants.link_shortener_salt)
              hash = hashids.encode(user.id,email.id,page.id,redirect.id)

              helper.generate_short_link(page, token).should == "http://getup.to/#{hash}"
            end
          end
        end

        it 'should return the link shortened url when invalid token' do
          campaign = create(:campaign)
          user = create(:user)
          token = EmailTrackingToken.encode(user.id, -1)
          page_sequence = create(:page_sequence, :campaign => campaign)
          page = create(:page, :page_sequence => page_sequence)
          redirect = Redirect.create! alias_path: 'test', target: 'http://test.host/campaigns/dummy-campaign-name/dummy-page-sequence-name'

          user_id, email_id = 0,0
          hashids = Hashids.new(AppConstants.link_shortener_salt)
          hash = hashids.encode(user_id,email_id,page.id,redirect.id)

          helper.generate_short_link(page, token).should == "http://getup.to/#{hash}"
        end
      end

      context 'with domain alias' do
        it 'should return the link shortened url' do
          campaign = create(:campaign)
          page_sequence = create(:page_sequence, :campaign => campaign)
          page = create(:page, :page_sequence => page_sequence)
          redirect = Redirect.create! alias_domain: 'test.org.au', target: 'http://test.host/campaigns/dummy-campaign-name/dummy-page-sequence-name'

          user_id, email_id = 0,0
          hashids = Hashids.new(AppConstants.link_shortener_salt)
          hash = hashids.encode(user_id,email_id,page.id,redirect.id)

          helper.generate_short_link(page, nil).should == "http://getup.to/#{hash}"
        end

        without_transactional_fixtures do
          it 'should return the link shortened url when valid token' do
            with_push_table do
              campaign = create(:campaign)
              user = create(:user)
              email = create(:email)
              token = EmailTrackingToken.encode(user.id, email.id)
              page_sequence = create(:page_sequence, :campaign => campaign)
              page = create(:page, :page_sequence => page_sequence)
              redirect = Redirect.create! alias_domain: 'test.org.au', target: 'http://test.host/campaigns/dummy-campaign-name/dummy-page-sequence-name'

              hashids = Hashids.new(AppConstants.link_shortener_salt)
              hash = hashids.encode(user.id,email.id,page.id,redirect.id)

              helper.generate_short_link(page, token).should == "http://getup.to/#{hash}"
            end
          end
        end

        it 'should return the link shortened url when invalid token' do
          campaign = create(:campaign)
          user = create(:user)
          token = EmailTrackingToken.encode(user.id, -1)
          page_sequence = create(:page_sequence, :campaign => campaign)
          page = create(:page, :page_sequence => page_sequence)
          redirect = Redirect.create! alias_domain: 'test.org.au', target: 'http://test.host/campaigns/dummy-campaign-name/dummy-page-sequence-name'

          user_id, email_id = 0,0
          hashids = Hashids.new(AppConstants.link_shortener_salt)
          hash = hashids.encode(user_id,email_id,page.id,redirect.id)

          helper.generate_short_link(page, token).should == "http://getup.to/#{hash}"
        end
      end
    end
  end

  describe '#no_target_alert_class' do
    context 'no postcode' do
      it 'should return no class' do
        helper.no_targets_alert_class(nil, nil).should be_blank
      end
    end

    context 'postcode' do
      before do
        @postcode = create(:postcode)
      end

      context 'no target' do
        before do
          @target = nil
        end

        context 'no target options' do
          it 'should return class' do
            helper.no_targets_alert_class(nil, @target, @postcode).should == 'alert alert-error'
          end
        end

        context 'target options' do
          it 'should return no class' do
            mp1 = create(:mp)
            mp2 = create(:mp)
            target_options = [mp1, mp2]
            helper.no_targets_alert_class(target_options, @target, @postcode).should be_blank
          end
        end
      end

      context 'target' do
        before do
          @target = create(:mp)
        end

        context 'no target options' do
          it 'should return no class' do
            helper.no_targets_alert_class(nil, @target, @postcode).should be_blank
          end
        end
      end
    end
  end
end
