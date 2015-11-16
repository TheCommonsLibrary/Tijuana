module ListCutter
  class CampaignRule < Rule
    fields :campaigns
    validates :campaigns, :presence => { :message => "Please select one or more campaigns" }

    def to_relation
        operator = negate? ? "not in" : "in"
        if operator=="not in"
          # Excludes all users who action_taken, external_action, Subscribed and Unsubscribed to given campaign list
          User.joins("LEFT OUTER JOIN user_activity_events as uae_c ON uae_c.`user_id` = `users`.id AND uae_c.activity in ('#{UserActivityEvent::Activity::ACTION_TAKEN}', '#{UserActivityEvent::Activity::EXTERNAL_ACTION}') AND uae_c.campaign_id in ('#{campaigns.join("','")}')")
              .where("uae_c.id is NULL")
        else
          User.joins("INNER JOIN user_activity_events as uae_c ON uae_c.`user_id` = `users`.id")
              .where("uae_c.campaign_id #{operator.upcase} (?) AND (uae_c.activity = ? OR uae_c.activity = ?)", campaigns, UserActivityEvent::Activity::ACTION_TAKEN, UserActivityEvent::Activity::EXTERNAL_ACTION)
        end
    end
    
    def active?
      !campaigns.blank?
    end
  end
end
