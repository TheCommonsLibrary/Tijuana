class TargetListModule < EmailTargetsModule
  attr_accessor :list_target

  option_fields :target_email_list, :target_placeholder, :send_to_target

  validates :target_email_list, :presence => true
  validates :target_placeholder, :presence => true

  validate :target_email_list_must_be_valid
  validate :target_emails_must_be_valid

  def member_value_voice_module?
    true
  end

  def target_emails
    @target_email
  end

  def update_action_attributes_and_validate(params)
    @target_email = list_emails[params[:list_target]]

    @list_target = params[:list_target]
    user_email.for_target_list_module = true
    user_email.targets = self.target_emails unless @list_target.blank?
    user_email.send_to_target = send_to_target?
    super
  end

  def validate_length_of_target_emails?
    return false
  end

  def list_emails
    emails = {}
    self.target_email_list.split("\n").each do |email|
      if !email.blank?
        target = email.split('|', 2)
        emails[target[1].strip] = target[0].strip if target.size == 2 && target[1].present?
      end
    end
    emails
  end

  def target_emails_must_be_valid
    unless self.list_emails.values.nil?
      self.list_emails.values.collect {|e| e.split(/[,;]/) }.flatten.collect(&:strip).each do |address|
        unless (valid_email_format?(address))
          self.errors.add(:target_email, "#{address} is not a valid email address.")
        end
      end
    end
  end

  def target_email_list_must_be_valid
    unless self.target_email_list.nil?
      self.target_email_list.split("\n").each do |target_list_item|
        emails = target_list_item.split('|')[0]
        target = target_list_item.split('|')[1]

        if !target_list_item.include?('|') && !target_list_item.blank?
          self.errors.add(:target_email_list, "[ #{target_list_item} ] is not a valid format")
        elsif !target_list_item.blank? && (emails.blank? || target.blank?)
          self.errors.add(:target_email_list, "[ #{target_list_item} ] please add an email and a target")
        end
      end
    end
  end

  def defaults
    self.target_placeholder = 'Find and select your local paper' unless self.target_placeholder
    self.target_email_list = "editorial@westsidenews.com.au | Brisbane West - Westside News\nletters@tcp.newsltd.com.au | Northern QLD - The Cairns Post" unless self.target_email_list
    self.send_to_target = '1' unless self.send_to_target == '0'
    super
  end

end

