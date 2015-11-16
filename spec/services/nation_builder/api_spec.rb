require 'spec_helper'

describe NationBuilder::Api do
  
  it "it should re-raise rate limit error and not retry" do
    stub_request(:get, %r{nationbuilder.com/api/v1/people/match}).to_return(:status => 429)
    expect { NationBuilder::Api.call_api :people, :match, email: 'melmember@example.com' }.to raise_error NationBuilder::RateLimitedError
    assert_requested :get, %r{nationbuilder.com/api/v1/people/match}, :times => 1
  end

  describe "#call_api" do

    context "with a 400 response for no matches" do
      let!(:json_response){ {"code"=>"no_matches", "message"=>"No people matched the given criteria."} }
      before{ stub_request(:get, %r{nationbuilder.com/api/v1/people/match}).to_return(status: 400, body: json_response.to_json) }

      it "should not raise and instead return the parsed JSON" do
        NationBuilder::Api.call_api(:people, :match, email: 'melmember@example.com').should == json_response
      end
    end

    context "with any other 400 response" do
      let!(:json_response){ {"message"=>"unknown 400 response"} }
      before{ stub_request(:get, %r{nationbuilder.com/api/v1/people/match}).to_return(status: 400, body: json_response.to_json) }

      it "should raise a NationBuilder::ClientError" do
        expect{
          NationBuilder::Api.call_api(:people, :match, email: 'melmember@example.com')
        }.to raise_error NationBuilder::ClientError
      end
    end

    context "with mocked NationBuilder::Client library" do
      let!(:payload){ {test: :test} }
      let!(:mocked_api){ double('NationBuilder::Client') }
      before{ NationBuilder::Client.stub(:new).and_return(double(call: payload)) }

      it "should add the fire_webhooks=false to all calls" do
        NationBuilder::Client.should_receive(:new).with(NATION_BUILDER[:site], NATION_BUILDER[:api_token], retries: 0)
          .and_return(mocked_api)
        mocked_api.should_receive(:call).with(:people, :create, {person: {external_id: 5}, fire_webhooks: false}).and_return(payload)
        NationBuilder::Api.call_api(:people, :create, {person: {external_id: 5}})
      end

      it "should create a NationBuilderSyncLog record" do
        NationBuilderSyncLog.should_receive(:create!) do |args|
          args[:started_at].should be_a(DateTime)
          args[:completed_at].should be_a(DateTime)
          args[:source].should == AppConstants.host
          args[:destination].should == NATION_BUILDER[:site]
          args[:endpoint].should == 'people/create'
          args[:payload].should == payload
          args[:user_id].should == 5
        end
        NationBuilder::Api.call_api(:people, :create, {person: {external_id: 5}})
      end

      context "with a nil payload returned by the client library" do
        let!(:payload){ nil }
        it "should raise a RuntimeError" do
          expect{
            NationBuilder::Api.call_api(:people, :create, {person: {external_id: 5}})
          }.to raise_error RuntimeError
        end
      end
    end
  end
end
