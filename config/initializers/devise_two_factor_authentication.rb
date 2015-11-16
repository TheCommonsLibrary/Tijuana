Devise.setup do |config|
  config.max_login_attempts = 40
  config.allowed_otp_drift_seconds = 900
end
