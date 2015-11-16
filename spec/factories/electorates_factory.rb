FactoryGirl.define do
  factory :electorate do
    name { generate(:name) }
    # there can be only one jurisdiction for each code
    jurisdiction { Jurisdiction.find_by_code("DONOTUSE") || create(:jurisdiction) }
  end
  
  factory :sydney_electorate, parent: :electorate do
    name { "Sydney" }
  end
  
  factory :sydney_federal, parent: :electorate do
    name { "Sydney Federal" }
  end
  
  factory :eden_monaro, parent: :electorate do
    name { "Eden-Monaro" }
  end

  factory :sydney_federal_second, parent: :electorate do
    name { "Sydney Federal Second Electorate" }
  end
  
  factory :sydney_local, parent: :electorate do
    name { "Sydney Local" }
  end
end
