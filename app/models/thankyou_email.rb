class ThankyouEmail
  include InlineTokenReplacement
  
  def initialize(page, user, content_module)
    @page = page
    @user = user
    @ask_module_text = ask_module_text(content_module)
  end
  
  def send!
    Emailer.thankyou_email(@user.email, @page.thankyou_email_subject, templated_body_text).deliver
  end
  handle_asynchronously(:send!) unless Rails.env == "test"
  
  private
  
  def templated_body_text
    replace_tokens(@page.thankyou_email_text, "NAME" => @user.greeting, "ASK_MODULE_TEXT" => @ask_module_text)
  end

  def ask_module_text(content_module)
    content_module.respond_to?(:ask_module_text) ? content_module.ask_module_text : ""
  end
end