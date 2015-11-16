FactoryGirl.define do
  factory :campaign do
    name         { "Dummy Campaign Name"  }
    description  { "Description of the campaign lorem ipsum dolor sit amet" }
    accounts_key { "Core" }
  end
end
