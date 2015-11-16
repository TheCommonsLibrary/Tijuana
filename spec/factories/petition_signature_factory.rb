FactoryGirl.define do
  factory(:petition_signature) do
    user
    page           { create(:page_with_parent) }
    content_module { create(:petition_module) }
  end
end
