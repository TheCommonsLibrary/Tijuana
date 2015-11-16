FactoryGirl.define do
  factory(:email) do |e|
    e.name              { "Dummy Email Name" }
    e.blast             { create(:blast) }
    e.sent_to_users_ids { "" }
  
    e.from_address      { "from@getup.org.au" }
    e.reply_to_address  { "reply@getup.org.au" }
    e.subject           { "Fwd: Fwd: Re: Fwd: LOL! Re: Funny cat pictures" }
    e.body              { "Look at these amusing cats!" }
  
    e.footer            { 'getup' }
  
  end
  
  factory :email_with_tokens, :class => Email do |e|
    e.name              { "Dummy Email Name" }
    e.blast             { create(:blast) }
    e.sent_to_users_ids { "" }
  
    e.from_address      { "from@getup.org.au" }
    e.reply_to_address  { "reply@getup.org.au" }
    e.subject           { "<TEST>Yes, {NAME|Friend}, we can! " }
    e.body              { "Dear {NAME|Friend}, I told you so! You live at {POSTCODE|Nowhere}. Pls click <a href=\"http://somewhere.com\">http://somewhere.com</a>" }

    trait(:secure_links) { secure_links true }
  end
  
  factory :email_with_custom_fragment, :class => Email do |e|
    e.name              { "Dummy Email Name" }
    e.blast             { create(:blast) }
    e.sent_to_users_ids { "" }
  
    e.from_address      { "from@getup.org.au" }
    e.reply_to_address  { "reply@getup.org.au" }
    e.subject           { "<TEST>Yes, {NAME|Friend}, we can! " }
    e.body              { "Dear {NAME|Friend}, CHECK OUT OUR VISION SURVEY! {CUSTOM_FRAGMENT|vision_survey_report_2014_link}" }
  
  end
  
  factory(:proofed_email, :class => Email, :parent => :email) do |e|
    e.after :create do |email|
      email.send_test!(['dummy@email.com'])
    end
  end
  

end
