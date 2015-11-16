module ListCutter
  class AgraRoleRule < Rule
    fields :role
    validates :role, :presence => { :message => "Please specify a existing role" }

    def to_relation
      role == 'all' ? all_role_rule : single_role_rule
    end

    def single_role_rule
      condition = AgraAction.arel_table[:role].eq(role)
      if negate?
        User.joins("LEFT OUTER JOIN agra_actions ON users.id = agra_actions.user_id AND #{condition.to_sql}").where("agra_actions.id IS NULL")
      else
        User.joins("INNER JOIN agra_actions ON users.id = agra_actions.user_id AND #{condition.to_sql}")
      end
    end

    def all_role_rule
      if negate? 
        User.joins("LEFT OUTER JOIN agra_actions ON users.id = agra_actions.user_id").where("agra_actions.id IS NULL")
      else
        User.joins("INNER JOIN agra_actions ON users.id = agra_actions.user_id")
      end
    end

    def active?
      !role.blank?
    end

    def has_agra_rule?
      true
    end
  end
end
