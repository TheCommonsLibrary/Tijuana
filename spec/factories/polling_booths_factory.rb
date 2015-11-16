FactoryGirl.define do
  factory :polling_booth do |polling_booth|
    polling_booth.postcode { create(:postcode)}
    polling_booth.electorate {create(:electorate)}
    polling_booth.latitude { -33.99 }
    polling_booth.longitude { 151.1 }
  end
end