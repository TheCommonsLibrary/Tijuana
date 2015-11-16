FactoryGirl.define do
  factory :jurisdiction do
    name { "for use in factories only" }
    code { "DONOTUSE" }
  end

  factory :federal_jurisdiction, :class => Jurisdiction do |t|
    t.name  { "Federal" }
    t.code  { "FEDERAL" }
    t.upper_house_present  { true }
  end
  
  factory :federal_jurisdiction_with_parties, :class => Jurisdiction do |t|
    t.name  { "Federal" }
    t.code  { "FEDERAL" }
    t.upper_house_present  { true }
    t.parties {|parties| [parties.association(:party), parties.association(:party, :name => "tea party", :abbreviation => "TEA")]}
  end
  
  factory :nsw_jurisdiction, :class => Jurisdiction do |t|
    t.name  { "New South Wales" }
    t.code  { "NSW" }
    t.upper_house_present  { true }
  end
  
  factory :tas_jurisdiction, :class => Jurisdiction do |t|
    t.name  { "Tasmania" }
    t.code  { "TAS" }
    t.upper_house_present  { true }
  end
  
  factory :getup_jurisdiction, :class => Jurisdiction do |t|
    t.name  { "Getup" }
    t.code  { "GETUP" }
    t.upper_house_present  { true }
  end
  
  factory :getup_nsw_jurisdiction, :class => Jurisdiction do |t|
    t.name  { "Getup NSW" }
    t.code  { "GETUPNSW" }
    t.upper_house_present  { true }
  end
  

end
