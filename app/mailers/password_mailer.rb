class PasswordMailer < Devise::Mailer
  helper :application

  def confirmation_instructions(record, token, opts={})
    super
  end

  def reset_password_instructions(record, token, opts={})
    super
  end

  def unlock_instructions(record, token, opts={})
    super
  end

  def deliver_all_admins_notification(record)
    devise_mail(record, :deliver_all_admins_notification)
  end

  def two_factor_authentication_instructions(record)
    devise_mail(record, :two_factor_authentication_instructions)
  end
end
