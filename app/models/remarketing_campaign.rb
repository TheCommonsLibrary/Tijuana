class RemarketingCampaign < ActiveRecord::Base
  scope :active, -> { where(active: true) }

  def tags
    read_attribute(:tags).split(',')
  end
end
