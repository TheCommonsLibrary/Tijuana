FactoryGirl.define do
  factory :event do |e|
    e.name                         { "Leo's party" }
    e.get_together                 { create(:get_together) }
    e.host                         { create(:user) }
    e.address                      { "51 Pitt St" }
    e.capacity                     { 10 }
    e.date                         { Date.today }
    e.time                         { 700 }
    e.terms_and_conditions         { true }
    e.address_latitude             { 0 }
    e.address_longitude             { 0 }
  end
  
  factory :confirmed_event, :class => Event do |e|
    e.name                         { "Confirmed Seriousness" }
    e.get_together                 { create(:get_together) }
    e.host                         { create(:user) }
    e.address                      { "51 Pitt St" }
    e.capacity                     { 10 }
    e.date                         { Date.today }
    e.time                         { 700 }
    e.terms_and_conditions         { true }
    e.confirmed_at                 { generate(:time) }
    e.address_latitude             { 0 }
    e.address_longitude             { 0 }
  end
  
  factory :cancelled_event, :class => Event do |e|
    e.name                         { "Confirmed Seriousness" }
    e.get_together                 { create(:get_together) }
    e.host                         { create(:user) }
    e.address                      { "51 Pitt St" }
    e.capacity                     { 10 }
    e.date                         { Date.today }
    e.time                         { 700 }
    e.terms_and_conditions         { true }
    e.confirmed_at                 { generate(:time) }
    e.canceled_at                  { generate(:time) }
    e.address_latitude             { 0 }
    e.address_longitude             { 0 }
  end
  
  factory :rollicking_good_time, :class => Event do |e|
    e.name                         { "Rollicking Good Time" }
    e.get_together                 { create(:get_together) }
    e.host                         { create(:user) }
    e.address                      { "Everywhere" }
    e.capacity                     { 100000 }
    e.date                         { Date.today }
    e.time                         { 700 }
    e.terms_and_conditions         { true }
    e.address_latitude             { 0 }
    e.address_longitude             { 0 }
  end
  
  factory :admin_managed_event, :class => Event do |e|
    e.name                         { "Dom's shindig" }
    e.get_together                 { create(:get_together, is_admin_managed: true) }
    e.host                         { create(:user) }
    e.address                      { "51 Pitt St" }
    e.capacity                     { 10 }
    e.date                         { Date.today }
    e.time                         { 700 }
    e.terms_and_conditions         { true }
    e.address_latitude             { 0 }
    e.address_longitude             { 0 }
  end
end
