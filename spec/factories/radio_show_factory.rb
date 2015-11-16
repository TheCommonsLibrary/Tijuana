FactoryGirl.define do
  factory :radio_show do |r|
    r.name { "Bum Radio" }
    r.presenter { "Aimee Li" }
    r.from_time { 2.hours.ago }
    r.to_time { Time.now }
    r.website { "http://www.aimeeli.com/livethelife" }
    r.show_type { "TALKBACK" }
  end

end