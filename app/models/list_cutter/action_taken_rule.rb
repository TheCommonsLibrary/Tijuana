module ListCutter
  class ActionTakenRule < Rule
    fields :page_ids
    fields :greater_than
    validates :greater_than, numericality: { greater_than_or_equal_to: 0, message: 'Number of action taken must be a number and greater or equal to 0'}
    validate :page_ids_numeric_and_exist

    def greater_than
      @params[:greater_than].to_i ||= 0
    end

    ACTION_ACTIVITIES = [UserActivityEvent::Activity::ACTION_TAKEN, 
                         UserActivityEvent::Activity::EXTERNAL_ACTION]

    def to_relation
      if greater_than == 0 #  optimise performance
        if negate?
          User.joins(on_user_activity_events(Arel::Nodes::OuterJoin)).where("user_activity_events.user_id IS NULL")
        else
          User.joins(on_user_activity_events(Arel::Nodes::InnerJoin))
        end
      else
        if negate?
          User.joins(
            "LEFT OUTER JOIN
              (#{users_with_actions.to_sql}) USERS_IDS_WITH_ACTIONS
              ON USERS_IDS_WITH_ACTIONS.id = users.id")
          .where("USERS_IDS_WITH_ACTIONS.id IS NULL")
        else
          User.joins(
              "JOIN
              (#{users_with_actions.to_sql}) USERS_IDS_WITH_ACTIONS
              ON USERS_IDS_WITH_ACTIONS.id = users.id")
        end
      end
    end


    def users_with_actions
      query = User.joins(:user_activity_events)
      query = query.where(:user_activity_events => {
              :activity => ACTION_ACTIVITIES,
              :page_id => page_ids_array})
      query.group('users.id').having("COUNT(users.id) > ?", greater_than).select('users.id')
    end

    def active?
      !page_ids.blank?
    end

private

    def on_user_activity_events(join_type)
      user = User.arel_table
      uae = UserActivityEvent.arel_table

      user.create_join(
          uae,
          uae.create_on(
              user[:id].eq(uae[:user_id]).
                  and(uae[:activity].in(ACTION_ACTIVITIES)).
                  and(uae[:page_id].in(page_ids_array))
          ),
          join_type
      )
    end

    def page_ids_array
      page_ids.split(',').map(&:to_i)
    end
    
    def page_ids_numeric_and_exist
      if (page_ids =~ /^[\d ,]+$/).nil?
        errors.add(:page_ids, "enter numbers only for page ids, comma separated for multiple")
      elsif
        bad_ids = page_ids_array.find_all {|id| !Page.find_by_id(id)}
        errors.add(:page_ids, "invalid page id(s) #{bad_ids.join(", ")}") unless bad_ids.empty?
      end
    end

  end
end
