class AgraAction < ActiveRecord::Base
  belongs_to :user
  
  def campaign_url
    "https://www.communityrun.org/petitions/#{slug}"
  end
  
  def campaign_name
    return 'Unknown' unless slug.present?
    slug.gsub(/-\d+$/, '').titlecase
  end
  
  def action_desc
    { 'creator' => 'created', 'signer' => 'signed' }[role]
  end
end
