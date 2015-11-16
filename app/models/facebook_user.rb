class FacebookUser < ActiveRecord::Base
  attr_accessible :facebook_id, :user_id
  validates_presence_of :facebook_id, :user_id
end
