module EmailModule

  EMAIL_DEFAULT = 'default'
  EMAIL_PLACEHOLDER = 'placeholder'

  def self.included(base)
    base.extend ClassMethods
    base.class_eval do
      # display_defaults is only present for backward compatability - 10/9/13
      option_fields :default_body, :default_subject, :display_defaults, :cc_me, :delayed_end_date, :button_text, :email_prompt_as, :send_to_target

      after_initialize :defaults

      validates :button_text, :length => { :minimum => 1, :maximum => 64 }
      validates :default_subject, :length => { :minimum => 2, :maximum => 255 }
      validates :default_body, :length => { :minimum => 10 }
    end

    base.send :include, InstanceMethods
    base.send :include, ActionView::Helpers::SanitizeHelper
  end  

  module ClassMethods
    def for_container?(layout_container)
      layout_container == :sidebar
    end
  end
  
  module InstanceMethods

    def update_user_email_attributes(user_email_attrs)
      user_email.attributes = user_email_attrs
      user_email.send_to_target = self.send_to_target?
    end

    def take_action(user, page, email=nil, params=nil, options={})
      raise DuplicateActionTakenError if UserEmail.where(:content_module_id => self, :user_id => user).count > 0
      user_email.user = user
      user_email.page = page
      user_email.email = email
      user_email.subject = default_subject if user_email.subject.blank? && !prompt_as_placeholder?
      user_email.body = strip_tags(user_email.body)
      user_email.body = default_body if user_email.body.blank? && !prompt_as_placeholder?
      user_email.subject = emoji_encode(user_email.subject)
      user_email.body = emoji_encode(user_email.body)
      body_without_signature = user_email.body
      user_email.body += body_signature(user,page) unless body_without_signature.blank?
      if create_action(user_email, options)
        user_email.send!
      else
        user_email.body = body_without_signature
        false
      end
    end

    def send_to_target?
      send_to_target != '0'
    end

    def legacy_display_defaults?
      self.display_defaults == '1'
    end

    def prompt_as_placeholder?
      email_prompt_as == EMAIL_PLACEHOLDER
    end

    def prompt_as_default?
      email_prompt_as == EMAIL_DEFAULT ||
      (email_prompt_as.blank? && legacy_display_defaults?)
    end

    def pro_forma_body?
      false
    end

    def has_hidden_default?
      true
    end

    def body_signature(user,page)
      return "" if user.nil?
      signature = ""
      signature += "#{user.first_name} " if user.first_name
      signature += "#{user.last_name}" if user.last_name
      signature += "\n#{user.email}" if user.email
      signature += "\n#{user.street_address}" if user.street_address && page.required_user_details[:street_address] == :required
      signature += "," if user.street_address && user.suburb && page.required_user_details[:street_address] == :required
      signature += "#{user.suburb}" if user.suburb && user.street_address && page.required_user_details[:suburb] == :required
      signature += "\n#{user.postcode.state} #{user.postcode.number}" if user.postcode && page.required_user_details[:postcode_number] == :required
      signature = "\n\n\n" + signature unless signature == ""
      return signature
    end
    private :body_signature

    def set_user_and_page(user, page)
      user_email.user = user
      user_email.page = page
    end

    def emoji_encode(text)
      return if text == nil
      Rumoji.encode(text)
    end
    private :emoji_encode
  end

end
