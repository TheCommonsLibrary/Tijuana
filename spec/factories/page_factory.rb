FactoryGirl.define do
  # warning, this factory is invalid!
  factory :page do
    name          { "Unnamed Page" }
    views         { 0 }
    required_user_details UserDetailsRequirements::DEFAULT_REQUIRED_USER_DETAILS.reduce({}) { |h, f| h[f[:field]] = :optional; h }
  end
  
  factory :page_with_parent, parent: :page do
    page_sequence { create(:page_sequence_with_parent) }

    trait(:user_details_default) {
      required_user_details UserDetailsRequirements::DEFAULT_REQUIRED_USER_DETAILS.reduce({}) { |h, f| h[f[:field]] = f[:default]; h }
    }
    trait(:user_details_required) {
      required_user_details UserDetailsRequirements::DEFAULT_REQUIRED_USER_DETAILS.reduce({}) { |h, f| h[f[:field]] = :required; h }
    }
  end
end
