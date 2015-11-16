FactoryGirl.define do
  factory :party do |t|
    t.name          { "Australian Faker Party" }
    t.abbreviation  { generate(:name) }
  end

end