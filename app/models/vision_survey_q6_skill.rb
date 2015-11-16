class VisionSurveyQ6Skill < ActiveRecord::Base
  has_and_belongs_to_many :vision_survey_results, join_table: "vision_survey_q6_skills_vision_survey_results"
end
