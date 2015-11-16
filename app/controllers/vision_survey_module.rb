module VisionSurveyModule
  def vision_survey_2014
    hash = Hash.new
    hash['completed_survey'] = false

    if params[:key] && (user = UserIdEncoder.decode(params[:key]))
      if user && (vision_survey_result = VisionSurveyResult.order(:created_at).find_by_user_id(user))
        hash['completed_survey'] = true

        priority_issue = vision_survey_result.q4_priority_issue
        if ['privacy', 'super', 'parental-leave'].include? priority_issue
          hash['q4_priority_issue'] = 'climate'
        else
          hash['q4_priority_issue'] = priority_issue
        end

        hash['q3_priorities'] = vision_survey_result.vision_survey_q3_priority_issues.collect { |issue| issue.name }
        hash['q18_transparency'] = vision_survey_result.q18_transparency

        social_media = vision_survey_result.social_media_usage
        hash['q10_facebook'] = social_media[:q10_facebook]
        hash['q11_youtube'] = social_media[:q11_youtube]
        hash['q12_twitter'] = social_media[:q12_twitter]
        hash['q13_blogging'] = social_media[:q13_blogging]
        hash['q14_google'] = social_media[:q14_google]

        set_user_specific_data! hash, user
        render_json hash, params
      else
        render :text => 'No valid key or token provided', :status => 401
      end
    elsif (token = TrackingTokenLookup.new(params[:t])).valid?
      user = token.user
      set_user_specific_data! hash, user
      render_json hash, params
    else
      render :text => 'No valid key or token provided', :status => 401
    end
  end

  private

  def render_json(hash, params)
    render :json => hash, :callback => params[:callback]
  end

  def set_user_specific_data!(hash, user)
    hash['events'] = {}

    if user.postcode
      vision_survey_data_by_postcode = VisionSurveyDataByPostcode.find_by_postcode_id(user.postcode)
      if vision_survey_data_by_postcode
        hash['postcode'] = user.postcode.number
        hash['state'] = user.postcode.state
        hash['members_in_postcode'] = vision_survey_data_by_postcode.approximate_num_of_members
        hash['events'] = {:climate_rallies => vision_survey_data_by_postcode.approximate_climate_rallies,
                          :election_volunteers => vision_survey_data_by_postcode.approximate_election_volunteers,
                          :election_booths => vision_survey_data_by_postcode.approximate_booths_covered}
      end
    end

    donor = get_donor_type(user)

    hash['name'] = user.first_name
    hash['suburb'] = user.suburb unless user.suburb.nil?
    hash['greeting'] = donor['greeting']
    hash['next_path'] = donor['next_path']
  end

  def get_donor_type(user)
    member_donations = Donation.where('user_id = ? AND active = ? AND last_donated_at is not NULL', user.id, true)
    recurring_donations = member_donations.where('frequency != ?', 'one_off').count
    one_off_donations = member_donations.where(frequency: 'one_off').count

    if recurring_donations > 0
      set_donor_type('core', 'survey1')
    elsif one_off_donations > 0
      set_donor_type('thanks', 'survey2')
    else
      set_donor_type('new', 'survey3')
    end
  end

  def set_donor_type(greeting, next_path)
    donor = Hash.new
    donor['greeting'] = greeting
    donor['next_path'] = next_path
    donor
  end
end
