class SecureLinkToken
  def self.token(tracking_token)
    Digest::SHA256.hexdigest("#{tracking_token}--#{AppConstants.secure_link_salt}")
  end
end
