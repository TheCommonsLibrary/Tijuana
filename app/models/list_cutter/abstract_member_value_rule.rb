module ListCutter
  class AbstractMemberValueRule < Rule
    fields :time_limit_months
    fields :value_range
    fields :lower_limit
    fields :upper_limit

    validates :time_limit_months, numericality: true, allow_blank: true
    validate :validate_time_limit
    validate :validate_fields

    RANGE_NOT_SELECTED = -1

    def to_relation
      if value_range_selected?
        return between_query if value_range_options[selected_value_range_index][1]
        return does_not_exist_query if value_range_options[selected_value_range_index] == value_range_options.first
        return greater_than_query if value_range_options[selected_value_range_index] == value_range_options.last
      else
        return does_not_exist_query if lower_limit.to_i == 0 && upper_limit.to_i == 0
        return less_than_query if lower_limit.to_i == 0 && upper_limit.to_i > 0
        return between_query if lower_limit.present? && upper_limit.present?
        return greater_than_query if upper_limit.blank?
      end
    end

    def active?
      value_range.present?
    end

  protected

    def does_not_exist_query
      if time_limit_months.present?
        User.joins(join_query(true))
          .where("#{member_value_alias}.id IS NULL")
      else
        User.where("`users`.id NOT IN (SELECT user_id FROM member_values WHERE value_type = ?)", value_type)
      end
    end

    def greater_than_query
      if time_limit_months.present?
        relation = User.select('`users`.id')
            .joins(join_query(false))
            .group('users.id')
            .having("sum(#{member_value_alias}.delta_value) >= ?", lower_limit_value)
        users_with_member_values(relation)
      else
        User.joins("JOIN member_values AS #{member_value_alias} ON #{member_value_alias}.`user_id` = `users`.id")
        .where("#{member_value_alias}.current = TRUE AND #{member_value_alias}.value_type = ? AND #{member_value_alias}.cumulative_value >= ?", value_type, lower_limit_value)
      end
    end

    def less_than_query
      if time_limit_months.present?
        relation = User.select('`users`.id')
                        .joins(join_query(true))
                        .group('users.id')
                        .having("sum(#{member_value_alias}.delta_value) <= ? OR sum(#{member_value_alias}.delta_value) IS NULL", higher_limit_value)
        users_with_member_values(relation)
      else
        User.joins("LEFT JOIN member_values AS #{member_value_alias} ON #{member_value_alias}.`user_id` = `users`.id AND #{member_value_alias}.current = TRUE AND #{member_value_alias}.value_type = #{User.sanitize(value_type)}")
        .where("#{member_value_alias}.cumulative_value <= ? OR #{member_value_alias}.cumulative_value IS NULL", higher_limit_value)
      end
    end

    def between_query
      if time_limit_months.present?
        relation = User.select('`users`.id')
                        .joins(join_query(false))
                        .group('users.id')
                        .having("sum(#{member_value_alias}.delta_value) >= ? AND sum(#{member_value_alias}.delta_value) <= ?", lower_limit_value, higher_limit_value)
        users_with_member_values(relation)
      else
        User.joins("JOIN member_values AS #{member_value_alias} ON #{member_value_alias}.`user_id` = `users`.id")
        .where("#{member_value_alias}.current = TRUE AND #{member_value_alias}.value_type = ? AND #{member_value_alias}.cumulative_value >= ? AND #{member_value_alias}.cumulative_value <= ?", 
         value_type, lower_limit_value, higher_limit_value)
      end
    end

  private

    def users_with_member_values(relation)
      User.joins("JOIN (#{relation.to_sql}) #{member_value_alias} ON #{member_value_alias}.id = users.id")
    end

    def join_query(left_join)
        sql = <<-SQL
          #{left_join ? "LEFT " : ''} JOIN  member_values #{member_value_alias}
          ON #{member_value_alias}.user_id = users.id
            AND #{member_value_alias}.created_at >= #{User.sanitize(time_limit_date)}
            AND #{member_value_alias}.value_type = #{User.sanitize(value_type)}
        SQL
    end

    def member_value_alias
      "member_value_#{value_type}"
    end

    def selected_value_range_index
      value_range.to_i
    end

    def higher_limit_value
      value = value_range_selected? ?  value_range_options[selected_value_range_index][1] : upper_limit.to_i
      is_currency? ? convert_to_cents(value) : value
    end

    def lower_limit_value
      value = value_range_selected? ?  value_range_options[selected_value_range_index][0] : lower_limit.to_i
      is_currency? ? convert_to_cents(value) : value
    end

    def convert_to_cents(dollar_value)
      (dollar_value.to_i) * 100
    end

    def validate_time_limit
      errors.add(:message, "Please select a positive integer for the time limit") if time_limit_months.present? && time_limit_months.to_i <= 0
    end

    def validate_fields
      errors.add(:message, "This would return all users. Please specify an upper limit if using zero as the lower limit.") if !value_range_selected? && lower_limit == '0' && upper_limit.blank?
      errors.add(:message, "Please either select a range from the dropdown or add a custom range") if !value_range_selected? && lower_limit.blank? && upper_limit.blank?
      errors.add(:message, "You cannot select a range from the dropdown and add a custom range") if value_range_selected? && (!lower_limit.blank? || !upper_limit.blank?)
      errors.add(:message, "Lower limit cannot be greater than upper limit") if !lower_limit.blank? && !upper_limit.blank? && lower_limit.to_i > upper_limit.to_i
    end

    def value_range_selected?
      return false if value_range.blank?
      value_range.to_i > RANGE_NOT_SELECTED
    end

    def time_limit_specified?
      return time_limit_months.present?
    end

    def time_limit_date
      (Time.now - time_limit_months.to_i.months).to_s
    end

  end
end
