FactoryGirl.define do
  factory :street do |s|
    s.name           { generate(:street) }
    s.suburb_name    { "Nicton"  }
  end

end