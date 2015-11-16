class SentEmail < ActiveRecord::Base
  belongs_to :email

  validates :body, presence: true
  validates :subject, presence: true
  validates :recipient_count, presence: true
  validates :sql, presence: true
end
