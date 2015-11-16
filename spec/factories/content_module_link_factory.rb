FactoryGirl.define do
  factory :content_module_link do |c|
    c.page              { create(:page_with_parent) }
    c.content_module    { create(:content_module) }
    c.position          { 1 }
    c.layout_container  { :main_content }
  end

end