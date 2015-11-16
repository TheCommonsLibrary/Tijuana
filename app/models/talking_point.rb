class TalkingPoint < ActiveRecord::Base

  validates :short_description, :long_description, presence: true

  def empty?
    short_description.blank? && long_description.blank?
  end
end
