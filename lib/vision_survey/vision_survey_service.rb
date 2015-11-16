class VisionSurveyService
  def self.record_results(result_row)
    vision_survey_priorities = self.create_priorities!(result_row)
    vision_survey_skills = self.create_skills!(result_row)
    vision_survey_result = self.create_vision_survey_result!(result_row, vision_survey_priorities, vision_survey_skills)
  end

  def self.record_summary_postcode_data(result_row)
    self.create_vision_survey_data_by_postcode! result_row
  end

  private

  def self.create_priorities!(result_row)
    priorities = []
    result_row.q3_priorities.each do |priority|
      priorities << VisionSurveyQ3PriorityIssue.find_or_create_by_name!(priority)
    end
    priorities
  end

  def self.create_skills!(result_row)
    skills = []
    result_row.q6_skills.each do |skill|
      skills << VisionSurveyQ6Skill.find_or_create_by_name!(skill)
    end
    skills
  end

  def self.create_vision_survey_result!(result_row, priorities, skills)
    VisionSurveyResult.create!(
      user: result_row.user,
      new_details_supplied: result_row.new_details_supplied?,
      vision_survey_q3_priority_issues: priorities,
      q4_priority_issue: result_row.q4_priority_issue,
      vision_survey_q6_skills: skills,
      q7_volunteering_open_text: result_row.q7_volunteering_open_text,
      q8_bequest: result_row.q8_bequest?,
      q9_major_donor: result_row.q9_major_donor?,
      q10_facebook: result_row.q10_facebook,
      q11_youtube: result_row.q11_youtube,
      q12_twitter: result_row.q12_twitter,
      q13_blogging: result_row.q13_blogging,
      q14_google: result_row.q14_google,
      q18_transparency: result_row.q18_transparency
    )
  end

  def self.create_vision_survey_data_by_postcode!(result_row)
    VisionSurveyDataByPostcode.create!(
      postcode: result_row.postcode,
      climate_rallies: result_row.climate_rallies,
      election_volunteers: result_row.election_volunteers,
      booths_covered: result_row.booths_covered,
      num_of_members: result_row.num_of_members
    )
  end
end