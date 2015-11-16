class CallMPModule < ContentModule

  include CustomFieldsForActions
  include JurisdictionFind

  option_fields :button_text, :display_defaults, :target_party_ids, :target_senate, :target_phone, :jurisdiction_code, :target, :show_steps, :contact_method
  typed_option_field :arbitrary_target, :boolean
  typed_option_field :schedule_calls, :boolean
  typed_option_field :schedule_start, :date
  typed_option_field :schedule_end, :date
  typed_option_field :schedule_frequency, :integer

  include TargetRepresentativeFinder

  after_initialize :defaults
  
  has_many :user_calls, :foreign_key => :content_module_id
  
  validates :button_text, :length => { :minimum => 1, :maximum => 64 }
  validates :target_phone, :inclusion => { :in => %w(parliament office), :message => "%{value} is not a valid target phone" }
  validates :target_phone, :inclusion => { :in => %w(office), if: :visit_target?, :message => "must be office if visiting and not calling" }
  validates :target_phone, :inclusion => { :in => %w(office), if: :mail_target?, :message => "must be office if mailing and not calling" }
  validates :contact_method, :inclusion => { :in => %w(phone visit mail), :message => "%{value} is not a valid contact method" }
  validates :target_party_ids, presence: true, if: '!arbitrary_target? && should_confirm_target_party_ids?'
  
  validates :schedule_start, :presence => true, :if => :schedule_calls
  validates :schedule_end, :presence => true, :if => :schedule_calls
  validates :schedule_frequency, :presence => true, :if => :schedule_calls
  validate :valid_schedule_range, :if => 'schedule_calls && schedule_start.present? && schedule_end.present?'
  
  def valid_schedule_range
    if schedule_start > schedule_end
      errors.add(:schedule_end, 'Schedule end should be on the same day as schedule start or in the future')
    end
  end

  def member_value_time_module?
    true
  end

  def show_steps?
    show_steps == '1'
  end

  def self.for_container?(layout_container)
    layout_container == :sidebar
  end
  
  def user_call
    @user_call ||= begin
      email = UserCall.new(:content_module => self)
      email
    end
  end
  
  def update_action_attributes_and_validate(params)
    user_call.targets = params[:targets]
    user_call.start_time = params[:mp] && params[:mp][:start_time]
    user_call.attributes = (params[:user_call] || {})
    user_call.valid?
  end

  def take_action(user, page, email=nil, params={}, options={})
    raise DuplicateActionTakenError if UserCall.where(:content_module_id => self, :user_id => user, :targets => params[:targets]).count > 0
    user_call.user = user
    user_call.page = page
    user_call.email = email
    create_action(user_call, options)
  end
  
  def display_defaults?
    self.display_defaults == '1'
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

  def set_user_and_page(user, page)
    user_call.user = user
    user_call.page = page
  end
  
  def time_slices
    slices = []
    start = schedule_start > Date.today ? schedule_start : Date.today
    (start..schedule_end).each do |date|
      next if ['Saturday', 'Sunday'].include?(date.strftime("%A"))
      start_slice = date.to_time + 9.hours
      while start_slice < date.to_time + 17.hours
        slices << [start_slice, start_slice + schedule_frequency.minutes]
        start_slice += schedule_frequency.minutes
      end
    end
    slices
  end
  
  def booked_user_calls(targets)
    @booked_user_calls ||= user_calls.where(:targets => targets).to_a
  end
  
  def booked_times(targets)
    booked_user_calls(targets).map &:start_time
  end
  
  def slice_available?(targets, from)
    !booked_times(targets).include?(from) && slice_ends_in_future?(from)
  end
  
  def slice_ends_in_future?(from)
    (from + schedule_frequency.minutes) > Time.now
  end
  
  def time_slices_in_a_day
    8.hours / schedule_frequency.minutes
  end
  
  def slice_taken_by(targets, from)
    booked_user_calls(targets).detect { |uc| uc.start_time == from }.try(:user)
  end

  def visit_target?
    contact_method == 'visit'
  end

  def mail_target?
    contact_method == 'mail'
  end
  
  private
  
  def defaults
    self.button_text = "I called!" unless self.button_text
    self.display_defaults = true unless self.display_defaults
    self.target_party_ids = {} unless self.target_party_ids
    self.target_senate = true if target_senate.nil?
    self.target_phone = "parliament" if target_phone.nil?
    self.contact_method = "phone" if contact_method.nil?
    self.public_activity_stream_template = "{NAME|A member} called their MP and asked them [something]." unless self.public_activity_stream_template
    self.jurisdiction_code = "FEDERAL" unless self.jurisdiction_code
    self.show_steps = '0' unless self.show_steps
  end

end
