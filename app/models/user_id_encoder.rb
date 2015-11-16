class UserIdEncoder
  def self.encode(user)
    vision_survey_hash = VisionSurveyHash.find_by_user_id(user)
    if vision_survey_hash.nil?
      key = SecureRandom.uuid
      VisionSurveyHash.create!(user: user, key: key)
    else
      key = vision_survey_hash.key
    end
    key
  end

  def self.decode(key)
    return nil if key.blank?
    result = VisionSurveyHash.find_by_key(key)
    return nil if result.nil?
    result.user
  end
end