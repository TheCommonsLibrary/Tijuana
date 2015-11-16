# "Email Targets Ask" module -- requests that user write and send their email or use the default one
class EmailTargetsModule < ContentModule

  include CustomFieldsForActions
  include EmailModule
  include TalkingPoints

  include EmailFormatHelper

  option_fields :target_emails
  
  validates :target_emails, :length => { :minimum => 5 }, :if => :validate_length_of_target_emails?
  validate :target_emails_must_be_valid

  def member_value_voice_module?
    true
  end

  def user_email
    @user_email ||= begin
      email = UserEmail.new(:content_module => self)
      email.subject = default_subject if prompt_as_default?
      email.body = default_body if prompt_as_default?
      email.targets = target_emails
      email
    end
  end
  
  def update_action_attributes_and_validate(params)
    update_user_email_attributes(params[:user_email])
    user_email.valid?
  end

  private
  
  def defaults
    self.button_text = "Send!" unless self.button_text
    self.cc_me = false unless self.cc_me
    self.email_prompt_as = EmailModule::EMAIL_DEFAULT unless self.email_prompt_as
    self.public_activity_stream_template = "{NAME|A member} emailed someone in support of [something]." unless self.public_activity_stream_template
    self.send_to_target = '1' unless self.send_to_target == '0'
  end
  
  def target_emails_must_be_valid
    unless target_emails.nil?
      Emailer.split_addresses(target_emails).each do |address|
        address.strip!
        unless (valid_email_format?(address))
          errors.add(:target_emails, "#{address} is not a valid email address.")
        end
      end
    end
  end

  def validate_length_of_target_emails?
    return true
  end
end
