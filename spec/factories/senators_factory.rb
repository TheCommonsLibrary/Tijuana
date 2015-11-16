FactoryGirl.define do
  factory :senator do |t|
    t.last_name         { "Superwoman senator" }
    t.first_name        { "Clark" }
    t.email             { generate(:email) }
    t.parliament_phone  { "(08) 93074839" }  
    t.parliament_fax    { "(08) 93074839" }
    t.office_address    { "123 Simple St" }
    t.office_suburb     { "Surry Hills" }
    t.office_state      { "NSW" }
    t.office_postcode   { "2011" }    
    t.office_fax        { "(08) 93074839" }
    t.office_phone      { "(08) 93074839" }
    t.state             { "NSW" }
    t.party             { create(:party) }
  end

end