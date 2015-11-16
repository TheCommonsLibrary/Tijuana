FactoryGirl.define do
  # abstract, general content module factory 
  # (don't use directly)
  factory :content_module do |c|
    c.updated_at { generate(:time) }
    c.created_at { generate(:time) }
  end
  
  factory :html_module, :parent => :content_module, :class => 'HtmlModule' do |c|
    c.type 'HtmlModule'
    c.content    { "<p>Lorem ipsum dolor sit amet</p>" * 5 }
    c.title      { "Lorem Ipsum" }
  end
  
  factory :html_module_with_image, :parent => :content_module, :class => 'HtmlModule' do |c|
    c.type 'HtmlModule'
    c.content    { "<p>Lorem ipsum dolor sit amet</p><img src='/whatever/module_img.png'" }
    c.title      { "Lorem Ipsum" }
  end
  
  factory :past_campaign_module, :parent => :content_module, :class => 'PastCampaignModule' do |c|
    c.type 'PastCampaignModule'
    c.content    { "<p>Lorem ipsum dolor sit amet</p>" * 5 }
    c.title      { "Lorem Ipsum" }
  end
  
  factory :testimonial_module, :parent => :content_module, :class => 'TestimonialModule' do |c|
    c.type 'TestimonialModule'
    c.number_of_comments  5
    c.comments_order      'social'
    c.title      { "Lorem Ipsum" }
    c.url      'https://www.getup.org.au/testimonial'
  end

  factory :petition_module, :parent => :content_module, :class => 'PetitionModule' do |c|
    c.type 'PetitionModule'
    c.signatures_target 10_000
    c.thermometer_threshold 500
    c.button_text 'Sign the petition!'
    c.content    { "<p>Lorem ipsum dolor sit amet</p>" * 5 }
    c.title      { "Lorem Ipsum" }
    c.petition_statement { "We want stuff" }
  end
  
  factory :email_targets_module, :parent => :content_module, :class => 'EmailTargetsModule' do |c|
    c.type 'EmailTargetsModule'
    c.default_body { "<p>Lorem ipsum dolor sit amet</p>" * 5 }
    c.default_subject {"This is the default subject line"}
    c.target_emails {"email1@getup.org.au, email2@getup.org.au, email3@getup.org.au"}
    c.email_prompt_as { EmailModule::EMAIL_DEFAULT }
    c.button_text {"Send your email!"}
    c.content    { "<p>Lorem ipsum dolor sit amet</p>" * 5 }
    c.title      { "Lorem Ipsum" }
    c.delayed_end_date  {""}
  end
  
  factory :merch_module, :parent => :content_module, :class => 'MerchModule' do |c|
    c.type 'MerchModule'
    c.content    { "<p>Lorem ipsum dolor sit amet</p>" * 5 }
    c.title      { "Lorem Ipsum" }
    c.thermometer_threshold 1000
    c.disable_paypal "1"
    c.personalised_amounts ""
    c.personalised_default_amount ""
  end
  
  factory :donation_module, :parent => :content_module, :class => 'DonationModule' do |c|
    c.type 'DonationModule'
    c.content    { "<p>Lorem ipsum dolor sit amet</p>" * 5 }
    c.title      { "Lorem Ipsum" }
    c.thermometer_threshold 1000
    c.disable_paypal "1"
    c.personalised_amounts ""
    c.personalised_default_amount ""
  end
  
  factory :donation_module_with_personalised_amounts, :parent => :donation_module, :class => 'DonationModule' do |c|
    c.personalised_amounts "10,100%,150%"
    c.personalised_default_amount "10"
  end
  
  factory :email_mp_module, :parent => :content_module, :class => 'EmailMPModule' do |c|
    c.type 'EmailMPModule'
    c.default_body { "<p>Lorem ipsum dolor sit amet</p>" * 5 }
    c.default_subject {"This is the default subject line"}
    c.button_text {"Send your email!"}
    c.content    { "<p>Lorem ipsum dolor sit amet</p>" * 5 }
    c.title      { "Lorem Ipsum" }
    c.delayed_end_date  {""}
    c.target_party_ids {{1 => '1', 2 => '0', 3 => '1'}}
  end
  
  factory :call_mp_module, :parent => :content_module, :class => 'CallMPModule' do |c|
    c.type 'CallMPModule'
    c.button_text {"I CALLED!"}
    c.content    { "<p>Lorem ipsum dolor sit amet</p>" * 5 }
    c.title      { "Lorem Ipsum" }
    c.target_party_ids {{1 => '1', 2 => '0', 3 => '1'}}
    c.schedule_calls false
    c.schedule_start Date.today
    c.schedule_end Date.today
    c.schedule_frequency 60
  end
  
  factory :radio_module, :parent => :content_module, :class => 'RadioModule' do |c|
    c.type 'RadioModule'
    c.button_text {"Called up the guys!"}
    c.title      { "Lorem Ipsum" }
  end
  
  factory :tell_a_friend_module, :parent => :content_module, :class => 'TellAFriendModule' do |c|
    c.type 'TellAFriendModule'
  end
  
  factory :invalid_html_module, :parent => :content_module, :class => 'HtmlModule' do |c|
    c.type 'HtmlModule'
    c.content    { "<p>Lorem ipsum dolor sit amet</p><a>" * 5 }
    c.title      { "Lorem Ipsum" }
  end
  
  factory :direct_landing_html_module, :parent => :content_module, :class => 'DirectLandingHtmlModule' do |c|
    c.type 'DirectLandingHtmlModule'
    c.content    { "<p>Lorem ipsum dolor sit amet</p>" }
    c.title      { "Direct Landing Html Module" }
  end
  
  factory :standfirst_module, :parent => :content_module, :class => 'StandfirstModule' do |c|
    c.type 'StandfirstModule'
    c.content    { "<p>Lorem ipsum dolor sit amet</p>" * 5 }
    c.title      { "Lorem Ipsum" }
  end
  
  factory :target_list_module, :parent => :content_module, :class => 'TargetListModule' do |c|
    c.type 'TargetListModule'
    c.default_body    { "<p>Send email to your targetted list</p>" * 5 }
    c.default_subject {"This is the default subject line"}
    c.button_text     {"Send your email!"}
    c.title           { "Target List" }
    c.target_placeholder  { 'Find and select your local paper' }
    c.target_email_list { "editorial@citynorthnews.com.au | Brisbane North - City-North News" }
  end
  
  factory :email_pledges_module, :parent => :content_module, :class => 'EmailPledgesModule' do |c|
    c.type 'EmailPledgesModule'
    c.default_body    { "<p>Send email to your targetted list</p>" * 5 }
    c.default_subject {"This is the default subject line"}
    c.pro_forma_prefix {"prefix"}
    c.pro_forma_suffix {"suffix"}
    c.button_text     {"Send your email!"}
    c.title           { "Target List" }
  end

  factory :tell_a_friend_ask_module, :parent => :content_module, :class => 'TellAFriendAskModule' do |c|
    c.type 'TellAFriendAskModule'
    c.title           { "Share with your Friends!!" }
  end
  
  factory :doorknock_module, :parent => :content_module, :class => 'DoorknockModule' do |c|
    c.type 'DoorknockModule'
    c.title           { "Go get 'em!!" }
  end

  factory :donation_upgrade_module, :parent => :content_module, :class => 'DonationUpgradeModule' do |c|
    c.type 'DonationUpgradeModule'
    c.title { "Upgrade!" }
  end

  factory :image_share_module, :parent => :content_module, :class => 'ImageShareModule' do |c|
    c.type 'ImageShareModule'
    c.title { "Create and share your own image!" }
    c.image_src { 'https://cdn.com/default.png' }
  end
end
