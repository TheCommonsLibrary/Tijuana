require 'spec_helper'

describe NationBuilderWebhooksController do

  describe "#person_changed" do
    
    context "without a valid token in the url" do
      before { post :person_changed, webhooks_token: 'invalid' }
      specify{ response.status.should == 403 }
    end

    context "with a valid token in the url" do
      let(:person){ {'first_name' => 'test'} }
      before { NationBuilder::SyncUserFromNbToTjService.any_instance.should_receive(:sync!)
        .with(hash_including({'payload' => {'person' => person}})) }
      before { post :person_changed, payload: {person: person}, webhooks_token: NATION_BUILDER[:webhooks_token] }
      specify{ response.status.should == 200 }
    end
  end
end
