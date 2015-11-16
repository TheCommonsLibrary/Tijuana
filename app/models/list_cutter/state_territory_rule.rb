module ListCutter
  class StateTerritoryRule < Rule
    fields :states_territories, :no_state
    validates :states_territories, presence: {message: "Please select one or more states/territories"}, unless: :no_state?
    validate :only_states_or_no_state

    def to_relation
      return User.where("postcode_id #{is_operator} NULL") if no_state?
      User.joins(:postcode).where("postcodes.state #{in_operator} (?)", states_territories)
    end

    def active?
      !states_territories.blank? || no_state?
    end

    def no_state?
      no_state == '1'
    end

    private
    def only_states_or_no_state
      errors.add(:message, "Please select EITHER states from the list OR tick unknown states") if states_territories.present? && no_state?
    end

    def is_operator
      negate? ? "is not" : "is"
    end

    def in_operator
      negate? ? "not in" : "in"
    end
  end
end
