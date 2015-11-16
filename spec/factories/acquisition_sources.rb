FactoryGirl.define do
  factory :acquisition_source do |f|
    source "fb"
    medium "org"
    content "v1"
    name "-test name with!"
    f.user { create(:user) }
  end

end
