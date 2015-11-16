FactoryGirl.define do
  factory :theme do |c|
    c.name { "application" }
    c.display_name { "Default" }
    initialize_with { Theme.where(name: "application", display_name: "Default").first_or_create }
  end
  
  factory :theme_happy, :parent => :theme do |c|
    c.name { "happy" }
    c.display_name { "happy - testing theme" }
  end

end
