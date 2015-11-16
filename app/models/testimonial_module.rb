class TestimonialModule < ContentModule
  option_fields :url, :number_of_comments, :comments_order
  validates_format_of :url, with: URI::regexp(%w(http https))

  def self.for_container?(layout_container)
    layout_container == :main_content
  end

  def self.comments_order_options
    ['social', 'reverse_time']
  end

  #not called 'take_action' since this is not an 'ask' module according to content_module#is_ask?
  def record_action(user, page, email=nil, params=nil, options={})
    if user && options[:facebook_id] && options[:app_id] && options[:testimonial_text]
      facebook_user = FacebookUser.find_or_create_by_user_id_and_facebook_id_and_app_id!(user.id, options[:facebook_id], options[:app_id]) 
      testimonial = Testimonial.create!(page: page, user: user, email: email, content_module: self, facebook_user_id: facebook_user.id, testimonial_text: options[:testimonial_text])
      create_action(testimonial, options)
    end
  end

  after_initialize do
    self.number_of_comments = 10 unless number_of_comments.present?
    self.comments_order = self.class.comments_order_options.first unless comments_order.present?
    self.public_activity_stream_template = "{NAME|A member} left a [testimonial]." unless self.public_activity_stream_template
  end
end
