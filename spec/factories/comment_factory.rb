FactoryGirl.define do
  factory :comment do |c|
    c.body            { 'this is a comment here' }                
    c.user            { create(:user) }
    c.updated_at      { generate(:time) }
    c.created_at      { generate(:time) }
  end
  

end