module ListCutter
  class PillarRule < Rule
    fields :pillars
    validates :pillars, presence: { message: "Please select one or more pillars" }

    ACTIONS = [
      UserActivityEvent::Activity::ACTION_TAKEN,
      UserActivityEvent::Activity::EXTERNAL_ACTION
    ]

    def to_relation
      if !negate?
        User.joins("INNER JOIN user_activity_events uae_p ON uae_p.user_id = users.id")
          .joins("INNER JOIN campaigns c ON uae_p.campaign_id = c.id")
          .where("c.accounts_key in (?)", pillars)
          .where("uae_p.activity in (?)", ACTIONS)
      else
        User.joins(<<-EOF
          LEFT JOIN user_activity_events uae_p
          INNER JOIN campaigns c ON uae_p.campaign_id = c.id
          and c.accounts_key in (#{pillars.map{|p| Campaign.sanitize(p)}.join(',')})
          on uae_p.user_id = users.id and
          uae_p.activity in (#{ACTIONS.map{|a| UserActivityEvent.sanitize(a)}.join(',')})
        EOF
        ).where('uae_p.id is null')
      end
    end

    def active?
      !pillars.blank?
    end
  end
end
