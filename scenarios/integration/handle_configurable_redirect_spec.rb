require File.dirname(__FILE__) + "/../scenario_helper.rb"

describe 'HandleConfigurableRedirect', type: :request do
  context 'redirect to external site' do
    it 'should register one email clicked event' do
      with_push_table do
        user = create(:user)
        push = create(:push)
        blast = create(:blast, push: push)
        email = create(:email, blast: blast)
        token = EmailTrackingToken.encode(user.id, email.id)
        Redirect.create!(alias_path: 'test', target: 'https://www.test.com')
        host! 'localhost'
        get '/test', t: token
        push.count_by_activity(:email_clicked).should eql 1
        response.status.should eql 302
      end
    end

    it 'should not register an email clicked event' do
      with_push_table do
        user = create(:user)
        push = create(:push)
        blast = create(:blast, push: push)
        email = create(:email, blast: blast)
        token = EmailTrackingToken.encode(user.id, email.id)
        Redirect.create!(alias_path: 'test', target: 'http://www.test.com')
        host! 'localhost'
        post '/test', t: token
        push.count_by_activity(:email_clicked).should eql 0
        response.status.should eql 302
      end
    end
  end

  context 'hit a getup site page' do
    it 'should register one email clicked event' do
      with_push_table do
        user = create(:user)
        push = create(:push)
        blast = create(:blast, push: push)
        email = create(:email, blast: blast)
        token = EmailTrackingToken.encode(user.id, email.id)
        campaign = create(:campaign, name: 'test_campaign')
        page_sequence = create(:page_sequence, campaign: campaign, name: 'test_page_sequence')
        page = create(:page, page_sequence: page_sequence, name: 'test_page')
        host! 'localhost'
        get '/campaigns/test_campaign/test_page_sequence/test_page', t: token
        push.count_by_activity(:email_clicked).should eql 1
        response.body.should match /#{page.name}/
      end
    end
  end

  context 'hit beacon.gif' do
    it 'should register one view event and no email clicked event' do
      with_push_table do
        user = create(:user)
        push = create(:push)
        blast = create(:blast, push: push)
        email = create(:email, blast: blast)
        token = EmailTrackingToken.encode(user.id, email.id)
        host! 'localhost'
        get '/beacon.gif', t: token
        push.count_by_activity(:email_clicked).should eql 0
        push.count_by_activity(:email_viewed).should eql 1
      end
    end
  end

  context 'hit unsubscribe' do
    it 'should not register an email clicked event' do
      with_push_table do
        user = create(:user)
        push = create(:push)
        blast = create(:blast, push: push)
        email = create(:email, blast: blast)
        token = EmailTrackingToken.encode(user.id, email.id)
        host! 'localhost'
        get '/unsubscribe', t: token
        push.count_by_activity(:email_clicked).should eql 0
      end
    end
  end
end