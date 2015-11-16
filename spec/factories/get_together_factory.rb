FactoryGirl.define do
  factory :get_together do |p|
    p.name                { "All for the Kittens!"  }
    p.description         { "All for the Kittens!"  }
    p.campaign            { create(:campaign) }
    p.from_date           { Date.yesterday }
    p.to_date             { Date.today + 5 }
    p.from_time           { 700 }
    p.to_time             { 900 }
    p.deleted_at          nil
    p.theme               { create(:theme) }
    p.search_radius       { 50 }
  end

end