module ListCutter
  class MemberValueTimeRule < AbstractMemberValueRule
    def value_type
      'time'
    end

    def is_currency?
      false
    end

    def value_range_options
      [
        [0],
        [1, 2],
        [3, 6],
        [7]
      ]
    end
  end
end
