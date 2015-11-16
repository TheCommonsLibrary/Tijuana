module ListCutter
  class EmailedUsersQuery
    def initialize(since:)
      unless since.is_a? Time
        raise ArgumentError, "'since' must be a Time to avoid timezone discrepancies"
      end
      @time_since = since
    end

    def emailed_n_times(n)
      fragment = "#{count_alias}.emails_sent IS NULL OR #{count_alias}.emails_sent <= ?"
      users_from_pushes.where([fragment, n.to_i])
    end

    private
    attr_reader :time_since

    def users_from_pushes
      User.joins(union_of_pushes(all_pushes_within_time_period))
    end

    def all_pushes_within_time_period
      # rails auto-converts time_since to UTC here, but not when interpolated, as in `union_of_pushes`
      SentEmail.where("created_at >= ?", time_since).map{|sent| sent.email.blast.push }.uniq
    end

    def count_alias
      @time_since.utc.to_s(:db).gsub(/[^\d]/, '_')
    end

    def union_of_pushes(pushes)
      sql =  "LEFT OUTER JOIN ( "
      if pushes.empty?
        sql += "select null as user_id, null as emails_sent"
      else
        sql += "select user_id, count(*) as emails_sent from ("
        sql += pushes.map{|push|
          "select user_id, created_at from push_#{push.id} " +
          "where activity = 'email_sent'"
        }.join(" union all ")
        sql += ") as users_in_time_period where created_at >= '#{time_since.utc.to_s(:db)}' group by user_id "
      end
      sql += ") as #{count_alias} on users.id = #{count_alias}.user_id "
    end
  end
end
