FactoryGirl.define do
  factory :vision_survey_result do |c|
    c.user                        { create(:user) }
    c.new_details_supplied        { true }
    c.q4_priority_issue           { 'climate' }
    c.q10_facebook                { 'like' }
    c.q11_youtube                 { 'no' }
    c.q12_twitter                 { 'no' }
    c.q13_blogging                { 'unaware' }
    c.q14_google                  { 'no' }
    c.q18_transparency            { 'nimble' }
  end
end