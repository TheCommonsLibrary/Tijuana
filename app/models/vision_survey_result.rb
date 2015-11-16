class VisionSurveyResult < ActiveRecord::Base
  belongs_to :user
  has_and_belongs_to_many :vision_survey_q3_priority_issues, join_table: "vision_survey_q3_priority_issues_vision_survey_results"
  has_and_belongs_to_many :vision_survey_q6_skills, join_table: "vision_survey_q6_skills_vision_survey_results"

  def has_social_media?
    %w(use like).include?(q10_facebook) ||
        %w(use subscribe).include?(q11_youtube) ||
        %w(use follow).include?(q12_twitter) ||
        q13_blogging == 'haveblog' ||
        %w(use follow).include?(q14_google)
  end

  def social_media
    social_media_apps = []
    if %w(use like).include? q10_facebook
      social_media_apps << 'Facebook'
    end
    if %w(use subscribe).include? q11_youtube
      social_media_apps << 'YouTube'
    end
    if %w(use follow).include? q12_twitter
      social_media_apps << 'Twitter'
    end
    if q13_blogging == 'haveblog'
      social_media_apps << 'Blog'
    end
    if %w(use follow).include? q14_google
      social_media_apps << 'Google'
    end
    social_media_apps
  end

  def social_media_usage
    social_media_usage_hash = {}

    facebook = set_social_media_usage('like', q10_facebook)
    social_media_usage_hash[:q10_facebook] = facebook

    youtube = set_social_media_usage('subscribe', q11_youtube)
    social_media_usage_hash[:q11_youtube] = youtube

    twitter = set_social_media_usage('follow', q12_twitter)
    social_media_usage_hash[:q12_twitter] = twitter

    blog = {:uses => false}
    if q13_blogging == 'haveblog'
      blog[:uses] = true
    end
    social_media_usage_hash[:q13_blogging] = blog

    google = set_social_media_usage('follow', q14_google)
    social_media_usage_hash[:q14_google] = google

    social_media_usage_hash
  end

  private

  def set_social_media_usage(follow_type, result)
    social_media = {:uses => false, :follow => false}
    if result == follow_type
      social_media[:follow] = true
      social_media[:uses] = true
    elsif result == 'use'
      social_media[:uses] = true
    end
    social_media
  end
end
