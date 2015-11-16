module ListCutter
  class MemberValueMoneyRule < AbstractMemberValueRule
    def value_type
      'money'
    end

    def is_currency?
      return true
    end

    def value_range_options
      [
        [0],
        [1, 100],
        [101, 500],
        [501]
      ]
    end
  end
end
