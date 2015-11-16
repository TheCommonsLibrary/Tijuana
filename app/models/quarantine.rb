class Quarantine < ActiveRecord::Base
  belongs_to :user
  belongs_to :user_activity_event

  validates :user, presence: true
  validates :user_id, uniqueness: true

end
