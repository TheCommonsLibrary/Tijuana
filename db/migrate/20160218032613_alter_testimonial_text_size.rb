class AlterTestimonialTextSize < ActiveRecord::Migration
  def change
    change_table :testimonials do |t|
      t.change :testimonial_text, :text
    end
  end
end
