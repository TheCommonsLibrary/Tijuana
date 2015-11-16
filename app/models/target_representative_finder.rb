module TargetRepresentativeFinder

  def self.included(base)
    base.alias_method_chain :target, :default
  end

  # Deprecated: use target ['MP', 'MP or Senator', 'Senator']
  def target_senate?
    self.target_senate == '1'
  end


  def target_options
    [['MPs','MP'],['MPs with fallback to Senators if MP is not targeted','MP or Senator'],['Senators', 'Senator']]
  end

  def target_with_default
    return target_without_default if target_without_default.present?
    if target_senate?
      'MP or Senator'
    else
      'MP'
    end
  end

  def find_targeted_representatives(postcode)
    reps = target_finder.find_targeted_representatives(postcode).shuffle.slice(0..4)
    reps ? reps : []
  end

  def target_message(postcode)
    target_finder.target_message(postcode)
  end

  private

  def target_finder
    if target == 'Senator'
      TargetSenatorFinder.new(options[:target_party_ids], jurisdiction_code)
    else
      TargetMpFinder.new(options[:target_party_ids], jurisdiction_code, target == 'MP or Senator')
    end
  end



end
