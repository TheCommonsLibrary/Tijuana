require 'spec_helper'
require 'rake'

describe "import:sendgrid:drops" do
  include_context "rake"

  its(:prerequisites) { should include("environment")  }

  # we should probably define a behaviour for cases where they have dropped multiple times?

  shared_examples "unsubscribes users" do |options|

    let(:user){ create(:user, :email => random_email)  }
    let(:created){ "2012-09-06 02:03:18" }
    let(:api_response){ [{'email' => user.email, 'created' => created, 'reason' => 'ignored'}] }

    context "with mocked result from SendGrid" do

      before do
        OpenURI.stub_chain(:open_uri, :read).and_return([].to_json)
        OpenURI.should_receive(:open_uri).with(/#{options[:endpoint]}/)
          .and_return(double('api', read: api_response.to_json))
      end

      it "should by default only look for results in the last 10 days" do
        OpenURI.should_receive(:open_uri)
          .with(/start_date=#{10.days.ago.to_date.to_s}/)
          .at_least(1).times
        subject.invoke
      end

      it "should unsubscribe matching users with source #{options[:source]}" do
        subject.invoke
        user.reload
        user.is_member.should be false
        user.user_activity_events.email_drops.count.should == 1
        drop = user.user_activity_events.email_drops.first
        drop.activity.should == UserActivityEvent::Activity::EMAIL_DROPPED
        drop.source.should == "sg_#{options[:source]}"
        drop.created_at.to_s.split.first.should == created.split.first
      end

      it "should not create a solr delayed job" do
        expect { subject.invoke  }.to_not change{Delayed::Job.count}
      end

      context "with ALL=1 as an environment variable" do

        before do
          ENV.stub(:[]).and_return(nil)
          ENV.stub(:[]).with('ALL').and_return('1')
        end

        it "should leave off any date range" do
          OpenURI.should_receive(:open_uri)
            .with(/start_date=/)
            .never
          subject.invoke
        end
      end

      if options[:source] == 'bounce'
        context "if the reason is 'Message not accepted for policy reasons'" do

          let!(:api_response){ [{'email' => user.email, 'created' => created,
            'reason' => '554 5.7.9 Message not accepted for policy reasons.  See http://postmaster.yahoo.com/errors/postmaster-28.html'}] }

          it "should NOT unsubscribe the matching user" do
            subject.invoke
            user.reload
            user.is_member.should be true
            user.user_activity_events.email_drops.should be_empty
          end
        end

        context "if the reason is 'mailbox [is] full'" do

          let!(:api_response){ [{'email' => user.email, 'created' => created,
            'reason' => "550 This user's mailbox is full (XXXX@netspeed.com.au) - Try again later"}] }

          it "should NOT unsubscribe the matching user" do
            subject.invoke
            user.reload
            user.is_member.should be true
            user.user_activity_events.email_drops.should be_empty
          end
        end
      end
    end

    context "with stubbed internal method to access SENDGRID_CONFIG" do
      let(:mock_auth){ { 'username' => 'sendgrid', 'password' => 'secret' } }

      it "should use the SENDGRID_CONFIG to access the API" do
        Kernel.silence_warnings do
          SENDGRID_CONFIG = {'test' => mock_auth}
        end
        OpenURI.should_receive(:open_uri)
          .with(/api_key=#{mock_auth['password']}.*api_user=#{mock_auth['username']}/)
          .at_least(1).times
          .and_return(double('api', read: [].to_json))
        subject.invoke
      end
    end

  end

  context "with a response from the sendgrid API that contains hard bounced emails" do
    it_should_behave_like 'unsubscribes users', endpoint: 'bounces', source: "bounce"
  end

  context "with a response from the sendgrid API that contains invalid emails" do
    it_should_behave_like 'unsubscribes users', endpoint: 'invalidemails', source: 'invalid'
  end

  context "with a response from the sendgrid API that contains spam reports" do
    it_should_behave_like 'unsubscribes users', endpoint: 'spamreports', source: 'spam'
  end

  shared_examples "limits the date range with environment variables" do |env, query_parameter|

    let(:date){ '2013-03-01' }

    before do
      ENV.stub(:[]).and_return(nil)
      ENV.stub(:[]).with(env).and_return(date)
      OpenURI.stub_chain(:open_uri, :read).and_return([].to_json)
    end

    it "should set the start_date parameter when calling the API" do
      OpenURI.should_receive(:open_uri).with(/#{query_parameter}=#{date}/)
      subject.invoke
    end
  end

  context "with ENV['FROM'] set" do
    it_should_behave_like 'limits the date range with environment variables', 'FROM', 'start_date'
  end

  context "with ENV['TO'] set" do
    it_should_behave_like 'limits the date range with environment variables', 'TO', 'end_date'
  end

  protected

  # any reason you went with random rather than hard coded?
  def random_email
    "#{Digest::SHA1.hexdigest([Time.now, rand].join)}@test.com"
  end

end
