FactoryGirl.define do
  factory :user_activity_event  do |c|
    c.user_id { 0 }
  end
  
  factory :activity, :class => UserActivityEvent  do |c|
    c.user     { create(:leo) }
    c.activity { "action_taken" }
  end
  
  factory :brazilian_activity, :class => UserActivityEvent  do |c|
    c.user     { create(:brazilian_dude) }
    c.activity { "action_taken" }
  end
  
  factory :leo_activity, :class => UserActivityEvent  do |c|
    c.user     { create(:leo) }
    c.activity { "action_taken" }
  end
  
  factory :aussie_activity, :class => UserActivityEvent  do |c|
    c.user     { create(:aussie) }
    c.activity { "action_taken" }
  end
  
  factory :aussie_recurring_activity, :class => UserActivityEvent  do |c|
    c.user     { create(:aussie) }
    c.activity { "action_taken" }
    c.donation_frequency { "weekly" }
  end
  
  factory :leo_nonrecurring_activity, :class => UserActivityEvent  do |c|
    c.user     { create(:leo) }
    c.activity { "action_taken" }
    c.donation_frequency { "one_off" }
  end
  
  
  factory :brazilian_nonrecurring_activity, :class => UserActivityEvent  do |c|
    c.user     { create(:brazilian_dude) }
    c.activity { "action_taken" }
    c.donation_frequency { "one_off" }
  end
  
  factory :donation_action, :class => UserActivityEvent  do |c|
    c.user     { create(:aussie) }
    c.activity { "action_taken" }
    c.campaign { create(:campaign) }
    c.page     { create(:page_with_parent) }
    c.content_module  { create(:donation_module) }
  end
  
  factory :petition_action, :class => UserActivityEvent  do
    user
    campaign
    activity        { "action_taken" }
    page            { create(:page_with_parent) }
    content_module  { create(:petition_module) }
  end
  
  factory :call_mp_action, :class => UserActivityEvent  do |c|
    c.user     { create(:aussie) }
    c.activity { "action_taken" }
    c.campaign { create(:campaign) }
    c.page     { create(:page_with_parent) }
    c.content_module  { create(:call_mp_module) }
  end
  
  factory :attend_event_action_without_campaign, :class => UserActivityEvent  do |c|
    c.user     { create(:aussie) }
    c.activity { "action_taken" }
    c.get_together_event  { create(:event) }
  end
  
  factory :attend_event_action, :class => UserActivityEvent  do |c|
    c.user     { create(:aussie) }
    c.activity { "action_taken" }
    c.campaign { create(:campaign) }
    c.page     { create(:page_with_parent) }
    c.get_together_event  { create(:event) }
  end
  
  factory :action_taken_activity, :class => UserActivityEvent  do |c|
    c.user     { create(:aussie) }
    c.activity { "action_taken" }
    c.campaign { create(:campaign) }
    c.page     { create(:page_with_parent) }
  end
  
  factory :unsubscribed_activity, :class => UserActivityEvent  do |c|
    c.user     { create(:leo) }
    c.activity { "unsubscribed" }
  end
  
  factory :subscribed_activity, :class => UserActivityEvent  do |c|
    c.user     { create(:leo) }
    c.activity { "subscribed" }
  end
  
  factory :agra_unsubscribed_activity, :class => UserActivityEvent  do |c|
    c.user     { create(:leo) }
    c.activity { UserActivityEvent::Activity::AGRA_UNSUBSCRIBED }
  end
  
  factory :requested_less_email, :class => UserActivityEvent  do |c|
    c.user     { create(:leo) }
    c.activity { UserActivityEvent::Activity::REQUESTED_LESS_EMAIL }
  end
  
  factory :email_dropped, :class => UserActivityEvent  do |c|
    c.user     { create(:leo) }
    c.activity { UserActivityEvent::Activity::EMAIL_DROPPED }
  end

end
