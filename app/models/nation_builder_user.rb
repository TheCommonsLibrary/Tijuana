class NationBuilderUser < ActiveRecord::Base
  attr_accessible :nationbuilder_id, :nationbuilder_site, :user_id
  belongs_to :user

  def self.record_nationbuilder_id!(user_id, nb_user_id)
    site = AppConstants.nationbuilder_site
    if record = NationBuilderUser.find_by_nationbuilder_id_and_nationbuilder_site(nb_user_id, site)
      # Update this nation builder id if it was previously associated with another user due to a merge in NB
      record.update_attributes! user_id: user_id unless record.user_id == user_id
    else
      NationBuilderUser.create! user_id: user_id, nationbuilder_id: nb_user_id, nationbuilder_site: site
    end
  end
end
