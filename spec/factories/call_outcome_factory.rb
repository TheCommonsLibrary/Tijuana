FactoryGirl.define do
  factory :call_outcome do
    disposition { "No Answer" }
    campaign_type { "admin_outbound" }
    campaign_code { "admin" }
    campaign_name { "Donations Admin" }
  end
end
