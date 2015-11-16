class SentTriggerEmail < ActiveRecord::Base
  belongs_to :triggered_by, polymorphic: true
  belongs_to :user
  
  def to_s
    "template: #{key}, sent_date: #{sent_date}, user_id: #{user_id}, triggered_by_id: #{triggered_by_id}"
  end
end
