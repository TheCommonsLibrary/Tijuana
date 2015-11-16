require 'spec_helper'

describe WebhooksController do
  describe "#call_outcome" do
    context "without a valid token in the url" do
      before { post '/webhooks/call_outcome/invalid_token' }
      specify { expect(response.status).to eq 403 }
    end

    context "with a valid token in the url" do
      let(:payload) {{
        "id": "12345",
        "njDisposition": "Already Regular Giver",
        "campaign_type": "ood_to_rg",
        "campaign_code": "EF",
        "njCampaignName": "GetUp Democracy August 2017",
      }}
      before { post "/webhooks/call_outcome/#{AppConstants.webhook_token}", payload }
      specify{ expect(response.status).to eq 200 }
    end
  end
end
