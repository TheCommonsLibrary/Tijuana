class PrivilegedUser < User
  devise :password_archivable, :secure_validatable

  has_one_time_password

  def self.model_name
    User.model_name
  end

  def send_two_factor_authentication_code
    self.otp_secret_key ||= ROTP::Base32.random_base32
    PasswordMailer.two_factor_authentication_instructions(self).deliver
  end

  def need_two_factor_authentication?(request)
    !Rails.env.development?
  end
end
