module ListCutter
  class ExcludeQuarantineRule < Rule
    def to_relation
        User.joins('LEFT JOIN quarantines ON quarantines.user_id = users.id').where('quarantines.id IS NULL')
    end
  end
end
