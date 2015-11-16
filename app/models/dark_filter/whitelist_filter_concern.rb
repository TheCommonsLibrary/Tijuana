module DarkFilter
  module WhitelistFilterConcern
    extend ActiveSupport::Concern

    included do
      has_many :campaign_white_lists, foreign_key: 'dark_filter_id'
    end

    # Return filter that excludes members that in the experiment but are not
    # whitelisted for this particular campaign
    def filter(campaign)
      join_alias = "whitelist_#{id}"
      User.joins("left outer join campaign_white_lists #{join_alias} on users.id = #{join_alias}.user_id")
        .where("#{join_alias}.campaign_id is null or #{join_alias}.campaign_id = ?", campaign.id)
    end
  end
end
