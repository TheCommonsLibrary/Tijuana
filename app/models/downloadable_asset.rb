class DownloadableAsset < ActiveRecord::Base
  validates :link_text, presence: true

  acts_as_user_stampable
    
  FileTemplate = ":id-:filename"
  asset_opts = {
    whiny: true
  }
  if S3[:enabled]
    asset_opts.merge!(
      storage: :fog,
      fog_credentials: {
        provider: "AWS",
        aws_access_key_id: S3[:key],
        aws_secret_access_key: S3[:secret]
      },
      fog_directory: S3[:bucket],
      path: FileTemplate
    )
  else 
    # filesystem storage - development only
    asset_opts.merge!(
      storage: :filesystem,
      path: "#{Rails.root}/public/system/#{FileTemplate}"
    )
  end

  has_attached_file :asset, asset_opts
  validates_attachment_presence :asset
  do_not_validate_attachment_file_type :asset

  scope :latest, lambda { |n|
    order("updated_at DESC").
    limit(n)
  }

  def attachment?
    asset? && !asset_file_name.blank? && (S3[:enabled] || File.exists?(asset.path))
  end

  def name
    "#{id}-#{asset_file_name}"
  end
  
  def kilobytes
    asset_file_size / 1024 if asset_file_size
  end
end
