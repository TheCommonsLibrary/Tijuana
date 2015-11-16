FactoryGirl.define do
  factory :unsubscribe, :class => Unsubscribe do |u|
    u.user        { create(:user) }
    u.email       { create(:email) }
    u.created_at  { generate(:time) }
  end

end