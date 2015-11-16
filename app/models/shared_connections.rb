class SharedConnections < ActiveRecord::Base
  belongs_to :originator, :class_name => "User", :foreign_key => "originator_id"
  belongs_to :action_taker, :class_name => "User", :foreign_key => "action_taker_id"
  belongs_to :user_activity_event

  validates :originator, :presence => true
  validates :action_taker, :presence => true
  validates :user_activity_event, :presence => true
  validate :action_taker_is_not_originator

  private

  def action_taker_is_not_originator
    errors.add(:action_taker, 'Must be different from the originator') if action_taker == originator
  end
end
