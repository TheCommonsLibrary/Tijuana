FactoryGirl.define do
  factory :merge_record do |m|
    m.join_id { '1' }
    m.name { 'name' }
    m.value { 'St George' }
  end
end
