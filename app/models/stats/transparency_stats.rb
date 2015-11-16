module Stats
  class TransparencyStats

    def update
      stats = calculate_donations +
          [calculate_actions_taken] +
          [calculate_new_members] +
          [calculate_donors] +
          [calculate_first_donors]

      Stats::TransparencyMetric.transaction do
        Stats::TransparencyMetric.delete_all
        stats.each { |s| s.save! }
      end
    end


    def load
      Stats::TransparencyMetric.all(:order => :id)
    end

    private

    def calculate_donations
      sql = <<SQL
      select
        SUM(IF(t.created_at > DATE_SUB(NOW(),INTERVAL 1 DAY), 1, 0)) as nb_donations_day,
        SUM(IF(t.created_at > DATE_SUB(NOW(),INTERVAL 1 WEEK), 1, 0)) as nb_donations_week,
        SUM(IF(t.created_at > DATE_SUB(NOW(),INTERVAL 1 MONTH), 1, 0)) as nb_donations_month,
        SUM(IF(t.created_at > DATE_SUB(NOW(),INTERVAL 1 YEAR), 1, 0)) as nb_donations_year,
        SUM(IF(t.created_at > DATE_SUB(NOW(),INTERVAL 1 DAY), t.amount_in_cents, 0)) as total_donations_day,
        SUM(IF(t.created_at > DATE_SUB(NOW(),INTERVAL 1 WEEK), t.amount_in_cents, 0)) as total_donations_week,
        SUM(IF(t.created_at > DATE_SUB(NOW(),INTERVAL 1 MONTH), t.amount_in_cents, 0)) as total_donations_month,
        SUM(IF(t.created_at > DATE_SUB(NOW(),INTERVAL 1 YEAR), t.amount_in_cents, 0)) as total_donations_year,
        CAST(SUM(IF(t.created_at > DATE_SUB(NOW(),INTERVAL 1 DAY), t.amount_in_cents, 0)) / SUM(IF(t.created_at > DATE_SUB(NOW(),INTERVAL 1 DAY), 1, 0)) AS DECIMAL (20,2)) avg_donation_day,
        CAST(SUM(IF(t.created_at > DATE_SUB(NOW(),INTERVAL 1 WEEK), t.amount_in_cents, 0)) / SUM(IF(t.created_at > DATE_SUB(NOW(),INTERVAL 1 WEEK), 1, 0)) AS DECIMAL (20,2)) avg_donation_week,
        CAST(SUM(IF(t.created_at > DATE_SUB(NOW(),INTERVAL 1 MONTH), t.amount_in_cents, 0)) / SUM(IF(t.created_at > DATE_SUB(NOW(),INTERVAL 1 MONTH), 1, 0)) AS DECIMAL (20,2)) avg_donation_month,
        CAST((SUM(IF(t.created_at > DATE_SUB(NOW(),INTERVAL 1 YEAR), t.amount_in_cents, 0))) / (SUM(IF(t.created_at > DATE_SUB(NOW(),INTERVAL 1 YEAR), 1, 0))) AS DECIMAL (20,2)) avg_donation_year
      from donations d join transactions t on d.id=t.donation_id where t.successful=true;
SQL
      donations = ActiveRecord::Base.connection.execute(sql).to_a.flatten
      donations.each_index do |index|
        if index < 4
          donations[index].to_i
        else
          donations[index] = donations[index].to_i/100
        end
      end

      [
        Stats::TransparencyMetric.make('Donations', *donations[0..3]),
        Stats::TransparencyMetric.make('Donations Total', *donations[4..7]),
        Stats::TransparencyMetric.make('Average Donations', *donations[8..11])
      ]
     end

    def calculate_actions_taken
      sql = <<SQL
      select
        SUM(IF(created_at > DATE_SUB(NOW(),INTERVAL 1 DAY), 1, 0)) as nb_actions_taken_day,
        SUM(IF(created_at > DATE_SUB(NOW(),INTERVAL 1 WEEK), 1, 0)) as nb_actions_taken_week,
        SUM(IF(created_at > DATE_SUB(NOW(),INTERVAL 1 MONTH), 1, 0)) as nb_actions_taken_month,
        SUM(IF(created_at > DATE_SUB(NOW(),INTERVAL 1 YEAR), 1, 0)) as nb_actions_taken_year
      from user_activity_events
      where activity = "action_taken"
SQL
      sql_to_metric('Actions Taken', sql)
    end

    def calculate_new_members
      sql = <<SQL
      select
        SUM(IF(created_at > DATE_SUB(NOW(),INTERVAL 1 DAY), 1, 0)) as nb_new_members_day,
        SUM(IF(created_at > DATE_SUB(NOW(),INTERVAL 1 WEEK), 1, 0)) as nb_new_members_week,
        SUM(IF(created_at > DATE_SUB(NOW(),INTERVAL 1 MONTH), 1, 0)) as nb_new_members_month,
        SUM(IF(created_at > DATE_SUB(NOW(),INTERVAL 1 YEAR), 1, 0)) as nb_new_members_year
      from user_activity_events
      where activity = "subscribed"
SQL
      sql_to_metric('New Members', sql)
    end

    def calculate_donors
      sql = <<SQL
      select
        SUM(IF(min_last_donated_at > DATE_SUB(NOW(),INTERVAL 1 DAY), 1, 0)) as nb_donors_day,
        SUM(IF(min_last_donated_at > DATE_SUB(NOW(),INTERVAL 1 WEEK), 1, 0)) as nb_donors_week,
        SUM(IF(min_last_donated_at > DATE_SUB(NOW(),INTERVAL 1 MONTH), 1, 0)) as nb_donors_month,
        SUM(IF(min_last_donated_at > DATE_SUB(NOW(),INTERVAL 1 YEAR), 1, 0)) as nb_donors_year
      from (
        select user_id, MAX(last_donated_at) as min_last_donated_at from donations group by user_id
      ) as t
SQL
      sql_to_metric('Donors', sql)
    end

    def calculate_first_donors
      sql = <<SQL
      select
        SUM(IF(min_last_donated_at > DATE_SUB(NOW(),INTERVAL 1 DAY), 1, 0)) as nb_first_donors_day,
        SUM(IF(min_last_donated_at > DATE_SUB(NOW(),INTERVAL 1 WEEK), 1, 0)) as nb_first_donors_week,
        SUM(IF(min_last_donated_at > DATE_SUB(NOW(),INTERVAL 1 MONTH), 1, 0)) as nb_first_donors_month,
        SUM(IF(min_last_donated_at > DATE_SUB(NOW(),INTERVAL 1 YEAR), 1, 0)) as nb_first_donors_year
      from (
        select user_id, MIN(created_at) as min_last_donated_at from donations group by user_id
      ) as t
SQL
      sql_to_metric('First-time Donors', sql)
    end

    def sql_to_metric(name, sql)
      result = ActiveRecord::Base.connection.execute(sql).to_a.flatten.map { |a| a.to_i }
      Stats::TransparencyMetric.make(name, *result[0..3])
    end
  end
end
