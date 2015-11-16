FactoryGirl.define do
  factory :agra_action_signer, :class => AgraAction do |a|
    a.slug          { 'agra-slug' }
    a.role          { 'signer' }
    a.updated_at    { generate(:time) }
    a.created_at    { generate(:time) }
  end

  factory :agra_action_creator, :class => AgraAction do |a|
    a.slug          { 'agra-slug' }
    a.role          { 'creator' }
    a.updated_at    { generate(:time) }
    a.created_at    { generate(:time) }
  end
end
