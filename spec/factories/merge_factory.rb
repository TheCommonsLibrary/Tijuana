FactoryGirl.define do
  factory :merge

  factory :merge_with_whitelist, class: Merge do |m|
    before(:create) { Setting[:whitelist_merge_tokens] = "#{Setting[:whitelist_merge_tokens]}\npostcode.electorates.first.name\npostcode_id" }

    m.name { 'hospitals' }
    m.description { 'hospitals wildfire campaign election 16' }
    m.join_key { 'postcode.electorates.first.name' }
    m.join_cache_key { 'postcode_id' }
    m.join_field_name { 'ELECTORATE' }
  end
end
