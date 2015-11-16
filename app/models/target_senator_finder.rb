class TargetSenatorFinder

  def initialize(target_party_ids, jurisdiction_code)
    @target_party_ids = target_party_ids
    @jurisdiction_code = jurisdiction_code
  end

  def find_targeted_representatives(postcode)
    find_senators(postcode)
  end

  def target_message(postcode)
    if postcode.regions_by_jurisdiction_code(@jurisdiction_code).empty?
      "It appears this postcode does not belong to a region we are targeting. If this is an error please let us know at: help@getup.org.au"
    else
      target_message_for_postcode_with_regions(postcode)
    end
  end


  def target_message_when_falling_back(postcode, targets, falling_back_from_mp)
    if postcode.regions_by_jurisdiction_code(@jurisdiction_code).empty?
      "#{falling_back_from_mp.full_name} does not represent one of the target parties of this campaign, and it appears that this postcode does not belong to a region we are targeting in the Senate. If this is an error please let us know at: help@getup.org.au"
    else
      case targets.length
        when 0
         "#{falling_back_from_mp.full_name} does not represent one of the target parties of this campaign, and neither are any of your Senators, but thanks for your support."
        when 1
          "#{falling_back_from_mp.full_name} does not represent one of the target parties of this campaign."
        else
          "#{falling_back_from_mp.full_name} does not represent one of the target parties of this campaign. Please select a Senator from the list below:"
      end
    end
  end

  private

  def target_message_for_postcode_with_regions(postcode)
    senators = find_senators(postcode)
    case senators.length
      when 0
        "Sorry, #{get_senator_full_name(postcode)} does not represent one of the target parties of this campaign, but thanks for your support."
      when 1
        @show_email_specific_text ? "Your email will go to #{senators.first.full_name}." : ""
      else
        if postcode.regions_by_jurisdiction_code(@jurisdiction_code).size > 1
          message_prefix = "Your postcode crosses regions. "
        end
        "#{message_prefix}Please select a Senator from the list below:"
    end
  end

  def find_senators(postcode)
    regions_by_jurisdiction_code = postcode.regions_by_jurisdiction_code(@jurisdiction_code)
    senators_across_regions_in_postcode = regions_by_jurisdiction_code.collect { |e|
      targeted_senators_in_region = filter_by_target_party_ids(e.senators)
      targeted_senators_in_region.empty? ? e.senators : targeted_senators_in_region
    }.flatten
    # senators_across_regions_in_postcode contains only targeted senators for regions with targeted senators,
    # plus ALL senators for regions without targeted senators
    if filter_by_target_party_ids(senators_across_regions_in_postcode).empty?
      [] # if NO senators are targeted, there are no options
    else
      senators_across_regions_in_postcode #if SOME senators are targeted, return them all so that user can choose who _actually_ represents them
    end
  end

  def filter_by_target_party_ids(arg)
    arg.select { |e| @target_party_ids.include?(e.party.id) }
  end

  def get_senator_full_name(postcode)
    senators = postcode.regions_by_jurisdiction_code(@jurisdiction_code).map(&:senators).flatten
    if senators.size == 1
      senators.first.full_name
    else
      'your representative'
    end
  end

end