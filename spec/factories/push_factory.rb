FactoryGirl.define do
  factory :push do |p|
    p.name                { "Dummy Push Name"  }
    p.campaign            { create(:campaign) }
    p.deleted_at          nil
    p.updated_at          { generate(:time) }
    p.created_at          { generate(:time) }
  end

end