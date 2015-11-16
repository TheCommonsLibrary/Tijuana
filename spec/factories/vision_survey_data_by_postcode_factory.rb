FactoryGirl.define do
  factory :vision_survey_data_by_postcode do |c|
    c.postcode              { create(:postcode) }
    c.climate_rallies       { 48 }
    c.election_volunteers   { 357 }
    c.booths_covered        { 18 }
    c.num_of_members        { 2153 }
  end
end