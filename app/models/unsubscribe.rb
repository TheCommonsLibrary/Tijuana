class Unsubscribe < ActiveRecord::Base
  belongs_to :email
  belongs_to :user

  scope :not_community_run, -> { where(:community_run => false) }
end
