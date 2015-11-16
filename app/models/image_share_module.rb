class ImageShareModule < ContentModule
  has_many :image_shares, :foreign_key => :content_module_id
  option_fields :facebook_app_id, :image_src, :fb_page_description, :fb_page_name, :fb_page_caption, :caption_max_length, :caption_x, :caption_y, :font_url, :font_size_px, :font_family, :font_colour, :caption_default, :caption_right_padding
  typed_option_field :disable_user_details, :boolean
  typed_option_field :caption_uppercase, :boolean
  
  validates :image_src, :length => { :minimum => 1 }

  after_initialize :defaults

  def self.for_container?(layout_container)
    layout_container == :sidebar
  end

  def member_value_voice_module?
    true
  end

  def fb_app_id
    facebook_app_id.present? ? facebook_app_id : AppConstants.facebook_image_share_app_id
  end

  def update_action_attributes_and_validate(params)
    image_share.caption = params[:caption]
    image_share.image_url = image_src
  end
  
  def image_share
    @image_share ||= ImageShare.new( content_module: self )
  end

  def take_action(user, page, email=nil, params=nil, options={})
    image_share.user = user
    image_share.page = page
    image_share.email = email
    create_action(image_share, options)
  end
  
  def set_user_and_page(user, page)
    image_share.user = user
    image_share.page = page
  end
  
  private
  
  def defaults
    self.public_activity_stream_template = "{NAME|A member} shared an image for [a cause]." unless self.public_activity_stream_template
    self.fb_page_description = 'Create and share your own image' unless self.fb_page_description
    self.fb_page_name = 'GetUp Image generator' unless self.fb_page_name
    self.fb_page_caption = 'Checkout my latest creation!' unless self.fb_page_caption
    self.caption_max_length = '20' unless self.caption_max_length
    self.caption_right_padding = '300' unless self.caption_right_padding
    self.caption_x = '340' unless self.caption_x
    self.caption_y = '100' unless self.caption_y
    self.font_url = 'https://fonts.googleapis.com/css?family=Gloria+Hallelujah' unless self.font_url
    self.font_size_px = "64" unless self.font_size_px
    self.font_family = "Gloria Hallelujah" unless self.font_family
    self.font_colour = '000000' unless self.font_colour
  end
end
