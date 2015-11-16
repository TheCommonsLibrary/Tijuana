FactoryGirl.define do
  factory :nation_builder_sync_log do |c|
    c.source { 'source' }
    c.destination { 'destination' }
    c.started_at { 4.day.ago }
    c.completed_at { 3.day.ago }
    c.endpoint { '/test' }
  end
end
