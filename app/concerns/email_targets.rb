module EmailTargets
  extend ActiveSupport::Concern
  included do
    has_many :user_emails
  end

  def message_on_content_module_id(content_module_id, strip_the_signature: true)
    if email = user_emails.where(content_module_id: content_module_id).last
      strip_the_signature ? strip_the_signature(email.body) : email.body
    end
  end

  def strip_the_signature(text)
    text =~ /\n\n\n/ ? text.gsub(/\n\n\n.*/m, '').strip : text
  end
end
