module DarkFilter
  class CampaignWhiteList < ActiveRecord::Base
    belongs_to :dark_filter, foreign_key: 'dark_filter_id'
    belongs_to :joining_campaign, class_name: 'Campaign'
    belongs_to :campaign
    belongs_to :user
  end
end
