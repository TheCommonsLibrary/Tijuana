FactoryGirl.define do
  factory :active_campaign_whitelist_filter, class: DarkFilter::CampaignWhitelistFilter do |f|
    f.name{ "Test filter (active)" }
    f.recruiting { true }
    f.active_filter { true }
  end
  
  factory :generic_filter, class: DarkFilter::DarkFilter do |f|
    f.name{ "Test filter (active)" }
    f.recruiting { true }
    f.active_filter { true }
  end
  
  factory :agra_whitelist_filter, class: DarkFilter::AgraWhitelistFilter do |f|
    f.name{ "Test filter (active)" }
    f.recruiting { true }
    f.active_filter { true }
  end

end