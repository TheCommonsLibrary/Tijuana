module ListCutter
  class MemberValueVoiceRule < AbstractMemberValueRule
    def value_type
      'voice'
    end

    def is_currency?
      false
    end

    def value_range_options
      [
        [0],
        [1, 5],
        [6, 19],
        [20]
      ]
    end
  end
end
