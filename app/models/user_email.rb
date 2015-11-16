class UserEmail < ActiveRecord::Base
  include ActsAsUserResponse
  include CustomFieldsFromContentModule

  attr_accessor :for_target_list_module

  validates :subject, :presence => true, :length => { maximum: 255 }
  validates :body, :presence => true
  validate :email_target_is_selected

  def for_target_list_module
    @for_target_list_module
  end

  def for_target_list_module=(value)
    @for_target_list_module = value
  end

  def email_target_is_selected
    if for_target_list_module
      errors.add(:list_target, "^Please select a recipient") if targets.blank?
    else
      errors[:base] << "MP/Senator should be selected" if targets.blank?
    end
  end

  def send!
    common_args = [user.email_field, nil, emoji_decode(subject), emoji_decode(body)]
    Emailer.delay(:run_at => DateTime.now).target_email(user.email, *common_args) if cc_me?
    common_args << EmailTargetTrackingLog.generate_token(self)
    Emailer.delay(:run_at => when_to_run(content_module_id)).target_email(targets, *common_args) if send_to_target?
    return true
  end

  def when_to_run(content_module_id=nil)
    delayed_end_date = ContentModule.find(content_module_id).delayed_end_date
    return DateTime.now if delayed_end_date.blank? || delayed_end_date.to_date <= Date.today
    return random_datetime_excluding_hours_between_midnight_and_five_am(delayed_end_date)
  end

  private

  def emoji_decode(text)
    Rumoji.decode(text)
  end

  def random_datetime_excluding_hours_between_midnight_and_five_am(end_date)
    # `.to_time.to_date` converts to time in local zone, then date
    date = Kernel.rand((end_date.to_time.to_date - Date.today).to_i).days.from_now
    dateTime = DateTime.now.change(year: date.year, month: date.month, day: date.day)
    allowed_hours = (5..23).to_a
    return dateTime if (allowed_hours).include?(dateTime.hour)

    rand_hour = allowed_hours[rand(allowed_hours.length)]
    dateTime.change(hour: rand_hour, min: rand(59))
  end
end
