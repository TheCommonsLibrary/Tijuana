class EmailPledgesModule < ContentModule

  include CustomFieldsForActions
  include EmailModule
  include TalkingPoints

  option_fields :pro_forma_prefix, :pro_forma_suffix

  validate :pro_forma_prefix_or_suffix_present

  def pro_forma_prefix_or_suffix_present
    errors.add(:base, 'At least one of the pro forma prefix or suffix must be set') if pro_forma_prefix.blank? && pro_forma_suffix.blank?
  end

  def member_value_voice_module?
    true
  end

  def pro_forma_body?
    return true
  end

  def has_hidden_default?
    false
  end

  def user_email
    @user_email ||= begin
      email = UserEmail.new(:content_module => self)
      email.subject = default_subject if prompt_as_default?
      email.body = default_body if prompt_as_default?
      email
    end
  end

  def target_details_or_default
    @targets ||= []
    [3, @targets.length].max.times.map{|index| @targets[index] || ['', '']}
  end

  def update_action_attributes_and_validate(params)
    user_email.attributes = params[:user_email].except(:subject)
    @targets = params[:target_emails].zip(params[:target_names]).select{|email, name|
      !name.blank? || !email.blank?
    }
    user_email.targets = @targets.map(&:first).map(&:strip).join(',')
  end

  def take_action(user, page, email=nil, params=nil, options={})
    populate_user_email_template_from_params(user, page, email)
    original_body = user_email.body
    compile_user_email_body(user, page) unless original_body.blank?
    if !user_email.valid?
      user_email.body = original_body
      return false
    end

    if @targets.size > 30
      #fake a validation error
      user_email.errors[:base] << 'Maximum 30 targets allowed. Please clear some names and emails.'
      user_email.body = original_body
      return false
    end

    Emailer.split_addresses(user_email.targets).each_with_index do |target_email, index|
      target_user_email = user_email.dup
      target_user_email.targets = target_email
      if create_action(target_user_email, options)
        target_user_email.save!
        target_user_email.send!
        EmailPledge.create!(user_email: target_user_email, content_module: self, user: target_user_email.user,
                            target_email: target_email, target_name: @targets[index].last)
      end
    end
    true
  end

  private

  def compile_user_email_body(user, page)
    user_email.body = "#{pro_forma_prefix}\n#{user_email.body}" if pro_forma_prefix.present?
    user_email.body = "#{user_email.body}\n#{pro_forma_suffix}\n" if pro_forma_suffix.present?
    user_email.body += body_signature(user,page)
  end

  def defaults
    self.button_text = "Send!" unless self.button_text
    self.email_prompt_as = EmailModule::EMAIL_DEFAULT unless self.email_prompt_as
    self.public_activity_stream_template = "{NAME|A member} emailed someone in support of [something]." unless self.public_activity_stream_template
    self.pro_forma_prefix = '' unless self.pro_forma_prefix
    self.pro_forma_suffix = '' unless self.pro_forma_suffix
  end

  def populate_user_email_template_from_params(user, page, email)
    user_email.user = user
    user_email.page = page
    user_email.email = email
    user_email.subject = default_subject
    user_email.body = strip_tags(user_email.body)
    user_email.body = default_body if user_email.body.blank? && !prompt_as_placeholder?
    user_email.subject = emoji_encode(user_email.subject)
    user_email.body = emoji_encode(user_email.body)
  end
end
