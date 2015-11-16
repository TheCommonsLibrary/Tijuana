require "action_controller"
require "timecop"
require_relative "../../app/services/call_outcome_service"

payload = ActionController::Parameters.new({
  "id": "12345",
  "email": "member@example.com",
  "njAction": "",
  "njLeadId": "54321",
  "njCallDate": "2017/12/14 16:15:17",
  "home_number": "",
  "mobile_number": "0400000000",
  "njDisposition": "Already Regular Giver",
  "njCallDuration": "598",
  "njCampaignName": "GetUp Democracy August 2017",
  "njDialAttempts": "4",
  "njDialedNumber": "0400000000",
  "njUniqueCallId": "1513228517.34030",
  "njAllocationName": "GetUp Democracy August 2011-2015 Donors 100+",
  "njExternalLeadId": "",
  "campaign_type": "ood_to_rg",
  "campaign_code": "EF",
})

describe CallOutcomeService do
  before { Timecop.freeze(Time.local(2017, 12, 14, 17, 26)) }
  after { Timecop.return }

  let(:attributes) {{
    received_at: Time.now,
    call_date: "2017/12/14 16:15:17",
    user_id: 12345,
    email: "member@example.com",
    unique_call_id: "1513228517.34030",
    disposition: "Already Regular Giver",
    campaign_type: "ood_to_rg",
    campaign_code: "EF",
    campaign_name: "GetUp Democracy August 2017",
    allocation_name: "GetUp Democracy August 2011-2015 Donors 100+",
    dialed_number: "0400000000",
    dial_attempts: 4,
    call_duration: 598,
    payload: "{\"id\":\"12345\",\"email\":\"member@example.com\",\"njAction\":\"\",\"njLeadId\":\"54321\",\"njCallDate\":\"2017/12/14 16:15:17\",\"home_number\":\"\",\"mobile_number\":\"0400000000\",\"njDisposition\":\"Already Regular Giver\",\"njCallDuration\":\"598\",\"njCampaignName\":\"GetUp Democracy August 2017\",\"njDialAttempts\":\"4\",\"njDialedNumber\":\"0400000000\",\"njUniqueCallId\":\"1513228517.34030\",\"njAllocationName\":\"GetUp Democracy August 2011-2015 Donors 100+\",\"njExternalLeadId\":\"\",\"campaign_type\":\"ood_to_rg\",\"campaign_code\":\"EF\"}"
  }}

  describe "#process" do
    it "returns attributes for a CallOutcome instance creation" do
      expect(subject.process(payload)).to eq(attributes)
    end

    context "without a user_id" do
      let(:no_id) { payload.merge(id: nil) }
      it "doesn't return 0" do
        expect(subject.process(no_id)[:user_id]).to eq(nil)
      end
    end
  end
end
