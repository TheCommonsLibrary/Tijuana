class EventTrackingLog < ActiveRecord::Base
  attr_accessible :agent, :ip, :referrer, :user_id, :name, :context
  validates_presence_of :user_id, :name
  belongs_to :user

  scope :remarketing, -> { where(name: 'remarketing') }
end
