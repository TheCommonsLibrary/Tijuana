FactoryGirl.define do
  factory :region do |c|
    c.name        { generate(:name) }
  end
  
  factory :sydney_federal_region, :class => Region do |c|
    c.name        { "Sydney Federal Region" }
  end
  
  factory :sydney_local_region, :class => Region do |c|
    c.name        { "Sydney Local Region" }
  end
  
  factory :perth_federal_region, :class => Region do |c|
    c.name        { "Perth Federal Region" }
  end
end