FactoryGirl.define do
  factory :image do |c|
    c.image_file_name    { Rails.root + "spec/fixtures/images/wikileaks.jpg" }
    c.image_content_type { "image/jpeg" }
    c.image_file_size    { 28432 }
    c.created_at         { generate(:time) }
    c.updated_at         { generate(:time) }
  end

end