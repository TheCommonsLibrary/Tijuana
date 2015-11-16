FactoryGirl.define do
  factory(:user_email) do |f|
    f.user           { create(:user) }
    f.page           { create(:page_with_parent) }
    f.content_module { create(:email_targets_module) }
    f.subject        { "The Subject" }
    f.body           { "The Body" }
    f.targets        { "person1@example.com, person2@example.com" }
    f.updated_at     { generate(:time) }
    f.created_at     { generate(:time) }
  end

end