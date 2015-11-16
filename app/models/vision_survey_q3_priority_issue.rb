class VisionSurveyQ3PriorityIssue < ActiveRecord::Base
  has_and_belongs_to_many :vision_survey_results, join_table: "vision_survey_q3_priority_issues_vision_survey_results"

  def full_issue_name
    self.class.get_full_issue_name self.name
  end

  def self.get_full_issue_name(short_name)
    case short_name
      when 'refugees'
        'Asylum Seekers'
      when 'climate'
        'Climate'
      when 'csg'
        'CSG'
      when 'democracy'
        'Democracy - Voting'
      when 'forests'
        'Forests'
      when 'indigenous'
        'Indigenous'
      when 'marriage'
        'Marriage Equality'
      when 'abc'
        'Media - ABC'
      when 'safety-net'
        'Medicare'
      when 'privacy'
        'Online Privacy'
      when 'parental-leave'
        'Paid Parental Leave'
      when 'reef'
        'Reef'
      when 'super'
        'Super'
      when 'tpp'
        'TPP'
      else
        nil
    end
  end
end
