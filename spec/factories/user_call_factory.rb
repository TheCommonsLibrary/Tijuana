FactoryGirl.define do
  factory(:user_call) do |f|
    f.user              { create(:user) }
    f.page              { create(:page_with_parent) }
    f.content_module    { create(:call_mp_module) }
    f.start_time        { Date.today + 9.hours }
  end
end