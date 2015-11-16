class EmailMPModule < ContentModule

  include CustomFieldsForActions
  include EmailModule
  include TalkingPoints

  include JurisdictionFind

  option_fields :target_party_ids, :target_senate, :jurisdiction_code, :target, :show_steps

  include TargetRepresentativeFinder

  validates :target_party_ids, presence: true, if: 'should_confirm_target_party_ids?'

  def member_value_voice_module?
    true
  end

  def show_steps?
    show_steps == '1'
  end

  def user_email
    @user_email ||= begin
      email = UserEmail.new(:content_module => self)
      email.subject = default_subject if prompt_as_default?
      email.body = default_body if prompt_as_default?
      email
    end
  end

  def update_action_attributes_and_validate(params)
    user_email.targets = params[:targets]
    update_user_email_attributes(params[:user_email])
    user_email.valid?
  end


  def target_party_ids=(checkbox_hash)
    ids = checkbox_hash.select { |id, on| on == "1" }.keys.map(&:to_i)
    self.options[:target_party_ids] = ids
  end

  def targets_mp?(mp)
    target_party_ids.include?(mp.party_id)
  end

  def should_confirm_target_party_ids?
    if jurisdiction_code.blank?
      jurisdiction_info = Jurisdiction.find_by_code("FEDERAL")
    else
      jurisdiction_info = Jurisdiction.find_by_code(jurisdiction_code)
    end

    !jurisdiction_info.nil? && !jurisdiction_info.parties.empty?
  end

  private

  def defaults
    self.button_text = "Send!" unless self.button_text
    self.cc_me = false unless self.cc_me
    self.email_prompt_as = EmailModule::EMAIL_DEFAULT unless self.email_prompt_as
    self.target_party_ids = {} unless self.target_party_ids
    self.target_senate = true if target_senate.nil?
    self.public_activity_stream_template = "{NAME|A member} emailed their MP and asked them [something]." unless self.public_activity_stream_template
    self.delayed_end_date = nil unless self.delayed_end_date
    self.jurisdiction_code = "FEDERAL" unless self.jurisdiction_code
    self.show_steps = '0' unless self.show_steps
    self.send_to_target = '1' unless self.send_to_target == '0'
  end

end
