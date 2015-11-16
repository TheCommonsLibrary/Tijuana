class UpdateNotifier

  def initialize(event)
    @event = event
    @important_original = @event.attributes.select{ |k,v| Event.important_details.to_s.include?(k) }
  end

  def notify_attendees_if_important_update
    if @event.confirmed? && important_update?
      deliver_notification
    end
  end

  private

  def important_update?
    @important_original.each do |k, v|
      if @event.attributes[k] != nil && @event.attributes[k] != v
        return true
      end
    end
    false
  end

  def deliver_notification
    GetTogetherMailer.event_changed_attendees_notification_email(@event).deliver
  end
  handle_asynchronously(:deliver_notification) unless Rails.env == 'test'
end