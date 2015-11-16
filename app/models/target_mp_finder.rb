class TargetMpFinder

  def initialize(target_party_ids, jurisdiction_code, use_fallback)
    @use_fallback = use_fallback
    @target_party_ids = target_party_ids
    @jurisdiction_code = jurisdiction_code
  end

  def find_targeted_representatives(postcode)
    mps = find_mps(postcode)
    if mps.empty? && @use_fallback
      filter_by_target_party_ids(postcode.senators)
    else
      mps
    end
  end

  def target_message(postcode)
    if postcode.electorates_by_jurisdiction_code(@jurisdiction_code).empty?
      "It appears this postcode does not belong to an electorate we are targeting. If this is an error please let us know at: help@getup.org.au"
    else
      target_message_for_postcode_with_electorates(postcode)
    end
  end

  private

  def target_message_for_postcode_with_electorates(postcode)
    mps = find_mps(postcode)
    case mps.length
      when 0
        mp_not_targeted_message(postcode)
      when 1
        ""
      else
        if postcode.electorates_by_jurisdiction_code(@jurisdiction_code).size > 1
          message_prefix = "Your postcode crosses electorates. "
        end
        "#{message_prefix}Please select your representative from the list below:"
    end
  end

  def mp_not_targeted_message(postcode)
    mp_full_name = get_mp_full_name(postcode)
    unless @use_fallback
      "Sorry, #{mp_full_name} does not represent one of the target parties of this campaign, but thanks for your support."
    else
      senators = filter_by_target_party_ids(postcode.senators)
      case senators.size
        when 0
          "#{mp_full_name} does not represent one of the target parties of this campaign, and neither are any of your senators, but thanks for your support."
        when 1
          "#{mp_full_name} does not represent one of the target parties of this campaign."
        else
          "#{mp_full_name} does not represent one of the target parties of this campaign. Please select a Senator from the list below:"
      end
    end
  end

  def find_mps(postcode)
    electorates_by_jurisdiction_code = postcode.electorates_by_jurisdiction_code(@jurisdiction_code)
    mps_across_electorates_in_postcode = electorates_by_jurisdiction_code.collect { |e|
      targeted_mps_in_electorate = filter_by_target_party_ids(e.mps)
      targeted_mps_in_electorate.empty? ? e.mps : targeted_mps_in_electorate
    }.flatten
    # mps_across_electorates_in_postcode contains only targeted mps for electorates with targeted mps,
    # plus ALL mps for electorates without targeted mps
    if filter_by_target_party_ids(mps_across_electorates_in_postcode).empty?
      [] # if NO mps are targeted, there are no options
    else
      mps_across_electorates_in_postcode #if SOME mps are targeted, return them all so that user can choose who _actually_ represents them
    end
  end

  def filter_by_target_party_ids(arg)
    arg.select { |e| @target_party_ids.include?(e.party.id) }
  end

  def get_mp_full_name(postcode)
    mps = postcode.electorates_by_jurisdiction_code(@jurisdiction_code).map(&:mps).flatten
    if mps.size == 1
      mps.first.full_name
    else
      'Your representative'
    end
  end

end