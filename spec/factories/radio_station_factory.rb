FactoryGirl.define do
  factory :radio_station do |r|
    r.state { "NSW" }
    r.name { "Bum Radio" }
    r.phone { "123123123" }
    r.sms { "234242343" }
    r.fax { "123123111" }
    r.air { "10000AM" }
    r.broadcast_radius { 54 }
    r.latitude { "151.22" }
    r.longitude { "-33.86" }
  end

end