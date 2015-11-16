class CreateTestimonialTable < ActiveRecord::Migration
  def change
    create_table :testimonials do |t|
      t.integer :facebook_user_id
      t.string :testimonial_text
      t.integer :page_id
      t.integer :content_module_id
      t.integer :email_id
      t.integer :user_id

      t.timestamps
    end
  end
end
