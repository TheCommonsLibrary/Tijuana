class WeeklyUserStatistics
  attr_reader :new_members, :unsubscribed_members, :dropped_members, :requested_less_email

  def self.from(now, number_of_weeks)
    WeeklyUserStatistics.new(now, number_of_weeks)
  end

  def initialize(now, number_of_weeks)
    @number_of_weeks = number_of_weeks

    date_from = now - number_of_weeks.weeks

    sql = %Q{
      SELECT activity, COUNT(DISTINCT user_id)
      FROM user_activity_events
      WHERE (created_at >= '#{date_from}')
      AND activity in ('subscribed', 'unsubscribed', 'email_dropped')
      GROUP BY activity
    }

    @activity_counts = ActiveRecord::Base.connection.execute(sql).to_a.inject({}) {|hash, el| hash[el[0]] = el[1]; hash}

    @new_members = get_activity_count("subscribed")
    @unsubscribed_members = get_activity_count("unsubscribed")
    @dropped_members = get_activity_count("email_dropped")

    Rails.logger.info { "WeeklyUserStatistics New Members: #{@new_members}" }
    Rails.logger.info { "WeeklyUserStatistics Unsubscribed Members: #{@unsubscribed_members}" }
    Rails.logger.info { "WeeklyUserStatistics Dropped Members: #{@dropped_members}" }
  end

  private

  def get_activity_count(key)
    @activity_counts[key].to_i / @number_of_weeks.to_f
  end
end
