FactoryGirl.define do
  factory :page_sequence do
    name           { "Dummy Page Sequence Name" }
    facebook_image { "http://localhost/fb.png" }
    theme
  end
  
  factory :static_page_sequence, parent: :page_sequence do
    campaign { nil }
  end
  
  factory :page_sequence_with_parent, parent: :page_sequence do
    name { "Dummy Page Sequence Name" }
    campaign
    theme
  end

  factory :page_sequence_with_page, parent: :page_sequence_with_parent do
    after(:create) {|ps| ps.pages << build(:page)}
    after(:create) {|ps| ps.pages.each(&:save!) }
  end

  factory :pillar_sequence, parent: :page_sequence_with_page do
    pillar_show { true }
    title { 'pillar sequence title' }
    blurb { 'pillar sequence blurb' }
    facebook_image { 'https://example.com/fb.png' }
  end
end
