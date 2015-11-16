module ListCutter
  class NoEmailSentTodayRule < Rule
    fields :no_email_sent_today

    def active?
      no_email_sent_today.present?
    end

    def to_relation
      EmailedUsersQuery.new(since: Time.current.beginning_of_day).emailed_n_times(0)
    end
  end
end
