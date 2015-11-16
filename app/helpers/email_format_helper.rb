module EmailFormatHelper
  def valid_email_format?(email)
    return false if email.nil?
    ValidatesEmailFormatOf::validate_email_format(email).nil?
  end
end
