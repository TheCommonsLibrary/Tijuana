FactoryGirl.define do
  factory :list do |l|
    l.updated_at          { generate(:time) }
    l.created_at          { generate(:time) }
  end

end