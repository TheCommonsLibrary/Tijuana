FactoryGirl.define do
  factory :remarketing_campaign do
    content '<script>alert("remarket!")</script>'
    active true
    tags 'remarket'
    priority 0
  end
end
