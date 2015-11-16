class EmailPledge < ActiveRecord::Base
  attr_accessible :target_email, :target_name, :content_module, :user, :user_email

  belongs_to :user
  belongs_to :user_email
  belongs_to :content_module
  validates_presence_of :content_module_id, :user_id, :user_email_id
end
