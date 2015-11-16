module ListCutter
  class ExcludeUsersRule < Rule
    fields :push_id

    def to_relation
      activities_join = <<-JOIN.strip_heredoc
        LEFT OUTER JOIN push_#{push_id} push_events
          ON users.id = push_events.user_id
          AND push_events.activity = 'email_sent'
      JOIN
      User.joins(activities_join).where("push_events.user_id IS NULL")
    end
  end
end
