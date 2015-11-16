module ListCutter
  class ExcludeLowVolumeMembersRule < Rule

    def to_relation
      User.where('users.low_volume = false')
    end

  end
end
