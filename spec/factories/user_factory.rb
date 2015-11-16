FactoryGirl.define do
  factory :user do |c|
    c.email           { generate(:email) }
    c.is_member       { true }
    c.is_agra_member  { true }
  end
  
  factory :admin_user, :class => PrivilegedUser do |c|
    c.email           { 'admin-email@getup.org.au' }
    c.password        { 'thisIsASecurePassw0rd' }
    c.is_member       { true }
    c.is_agra_member  { true }
    c.is_admin        { true }
  end
  
  factory :volunteer_user, :class => PrivilegedUser do |c|
    c.email           { 'volunteer-user@getup.org.au' }
    c.password        { 'thisIsASecurePassw0rd' }
    c.is_member       { true }
    c.is_agra_member  { true }
    c.is_volunteer    { true }
  end
  
  factory :leo, :class => User do |c|
    c.email           { "leonardo@borges.com" }
    c.country_iso     { "BR" }
    c.postcode        {create(:postcode_of_maracana)}
    c.is_member       { true }
    c.is_agra_member  { true }
    c.updated_at      { generate(:time) }
    c.created_at      { generate(:time) }
  end
  
  factory :user_with_details, :class => User do |c|
    c.email           { 'test-user@getup.org.au' }
    c.first_name      { 'Test' }
    c.last_name      { 'User' }
    c.country_iso     { "AU" }
    c.suburb          { 'Sydney' }
    c.postcode     {create(:postcode_of_tw_office)}
    c.is_member       { true }
    c.is_agra_member  { true }
    c.updated_at      { generate(:time) }
    c.created_at      { generate(:time) }
  end
  
  factory :user_with_sync_tag, parent: :user_with_details do |u|
    u.after(:create) do |user|
      user.update_attributes :tag_list => 'tag (sync)'
    end
  end
  
  factory :brazilian_dude, :class => User do |c|
    c.email           { "another@dude.com" }
    c.country_iso     {"BR"}
    c.is_member       { true }
    c.is_agra_member  { true }
    c.postcode        {create(:postcode_of_maracana)}
    c.updated_at      { generate(:time) }
    c.created_at      { generate(:time) }
  end
  
  factory :aussie, :class => User do |c|
    c.email           { "aussie@dude.com" }
    c.country_iso     { "AU" }
    c.is_member       { true }
    c.is_agra_member  { true }
    c.postcode        {create(:postcode_of_tw_office)}
    c.updated_at      { generate(:time) }
    c.created_at      { generate(:time) }
  end
  
  factory :aussie_in_edgewater, :class => User do |c|
    c.email           { "aussie_edgewater@dude.com" }
    c.country_iso     { "AU" }
    c.is_member       { true }
    c.is_agra_member  { true }
    c.postcode        {create(:postcode_of_edgewater)}
    c.updated_at      { generate(:time) }
    c.created_at      { generate(:time) }
  end
  
  factory :unsubscribed_agra_user, :class => User do |c|
    c.email           { "agra_user@example.com" }
    c.is_member       { true }
    c.is_agra_member  { false }
    c.updated_at      { generate(:time) }
    c.created_at      { generate(:time) }
  end

  factory :user_for_nation_builder, :class => User, :parent => :user do |u|
    u.first_name "Test"
    u.last_name "User"
    u.after(:build) do |user|
      user.id = rand(1e8) + 1e8 # unique within NB, hopefully
    end
  end
end
