module ListCutter
  class EmailFrequencyRule < Rule
    fields :email_frequency
    fields :time_period
    validates :email_frequency, numericality: {greater_than_or_equal_to: 0, less_than_or_equal_to: 7}
    validates :time_period, numericality: {greater_than: 0, less_than_or_equal_to: 7}

    def active?
      email_frequency.present? && time_period.present?
    end

    def to_relation
      EmailedUsersQuery.new(since: time_period.to_i.days.ago).emailed_n_times(email_frequency.to_i)
    end
  end
end
