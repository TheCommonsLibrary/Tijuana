class EmailTargetTrackingLog < ActiveRecord::Base
  belongs_to :user_email
  attr_accessible :agent, :cookie, :ip, :referrer, :user_email_id, :user_email

  def self.generate_token(user_email)
    hashids.encode(user_email.id)
  end

  def self.decode_token(token)
    hashids.decode(token).first
  end

  MIN_HASH_LENGTH = 1
  ALPHABET = ([*'0'..'9',*'A'..'Z',*'a'..'z']).join
  def self.hashids
    Hashids.new(AppConstants.email_token_salt, MIN_HASH_LENGTH, ALPHABET)
  end
end
