require File.join(Rails.root, 'lib', 'paperclip_processors', 'resizer')

class Image < ActiveRecord::Base

  SIZES = [
    ["Home page slideshow image (770x443)", "770x443"],
    ["Campaign page main/header image (770px wide)", "770x"],
    ["Campaign page sidebar image (330px wide)", "330x"],
    ["Small photo (200px wide)", "200x"],
    ["Medium photo (360px wide)", "360x"],
    ["Facebook share image (1200x627)", "1200x627"],
    ["Custom", ""]
  ]

  FileTemplate = "image_:id_:style.:extension"
  image_opts = {
    default_style: :full,
    styles: {
      thumbnail: "120x120>",
      full: { processors: [:resizer] }
    },
    whiny: true,
    whiny_thumbnails: true
  }
  if S3[:enabled]
    image_opts.merge!(
      storage: :fog,
      fog_credentials: {
        provider: "AWS",
        aws_access_key_id: S3[:key],
        aws_secret_access_key: S3[:secret],
      },
      fog_directory: S3[:bucket],
      path: FileTemplate
    )
  else
    # filesystem storage - development only
    image_opts.merge!(
      storage: :filesystem,
      path: "#{Rails.root}/public/system/#{FileTemplate}"
    )
  end

  has_attached_file :image, image_opts
  validates_attachment_presence :image
  validates_attachment_content_type :image, content_type: /image\/\w+/

  before_create :measure_dimensions  

  attr_accessor :dimensions, :resize #, :height, :width

  acts_as_user_stampable

  scope :latest, lambda { |n|
    order("updated_at DESC").
    limit(n)
  }

  def attachment?
    image? && 
      !image_file_name.blank? &&
      (S3[:enabled] || File.exists?(image.path(:thumbnail)))
  end

  def name(format = :original)
    "image_#{id}_#{format.to_s}#{File.extname(image_file_name)}"
  end
  
  private
  
  def measure_dimensions    
    if tmp_img = image.queued_for_write[:full]
      dimensions = Paperclip::Geometry.from_file(tmp_img)
      self.image_width = dimensions.width
      self.image_height = dimensions.height
    end
  end
end
