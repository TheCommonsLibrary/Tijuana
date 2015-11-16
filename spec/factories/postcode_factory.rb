FactoryGirl.define do
  factory :postcode do |c|
    c.number      { generate(:postcode_number) }
    c.state       { "NSW" }
    c.longitude   { 144.1 }
    c.latitude    { -38.45 }
  end
  
  
  factory :postcode_of_tw_office, :class => Postcode do |c|
    c.number      { "2000" }
    c.state       { "NSW" }
    c.longitude   { 151.22921 }
    c.latitude    { -33.859583 }
    c.after :create do |postcode|
      postcode.electorates << create(:sydney_electorate)
    end
  end
  
  factory :postcode_for_darwin, :class => Postcode do |c|
    c.number      { "0800" }
    c.state       { "NT" }
    c.longitude   { 130.841932 }
    c.latitude    { -12.462258 }
  end
  
  factory :postcode_of_hobart, :class => Postcode do |c|
    c.number      { "7000" }
    c.state       { "TAS" }
    c.longitude   { 147.3250 }
    c.latitude    { -42.8806 }
  end
  
  
  factory :postcode_of_circular_quay, :class => Postcode do |c|
    c.number      { "2000" }
    c.state       { "NSW" }
    c.longitude   { 151.210027 }
    c.latitude    { -33.859725 }
  end
  
  factory :postcode_of_edgewater, :class => Postcode do |c|
    c.number      { "6027" }
    c.state       { "NSW" }
    c.latitude    {-33.221648}
    c.longitude   {151.530304}
  #  c.electorates {|e| e.association(:electorate) }
    c.after :create do |postcode|
      postcode.electorates << create(:electorate)
    end
  end
  
  factory :postcode_of_maracana, :class => Postcode do |c|
    c.number      { "9999" }
    c.state       { "Brasil" }
    c.latitude    {-20.742415}
    c.longitude   {126.826172}
  end
end