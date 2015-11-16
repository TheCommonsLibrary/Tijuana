FactoryGirl.define do
  factory :blast do |b|
    b.name                { "Dummy Blast Name"  }
    b.push                { create(:push) } 
    b.deleted_at          nil
    b.updated_at          { generate(:time) }
    b.created_at          { generate(:time) }
  end

end