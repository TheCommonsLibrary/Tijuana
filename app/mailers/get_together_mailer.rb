class GetTogetherMailer < GetupMailer
  include SendGrid
  include SendgridSupport
  include SendgridTokenReplacement
  include InlineTokenReplacement

  def thankyou_for_hosting_email(event)
    @event = event
    # pre_process_body!(event, event.get_together.host_greeting_email, event.host)
    mail(:to => event.host.email, :subject => "Please confirm your GetUp! Event.")
  end

  def event_created_and_public_confirmation_email(event)
    @event = event
    pre_process_body!(event, event.get_together.host_greeting_email, event.host)
    mail(:to => event.host.email, :subject => "Your \"#{event.name}\" event has been successfully created.")
  end
  
  def thankyou_for_attending_email(event, attendee)
    pre_process_body!(event, event.get_together.attendee_greeting_email, attendee)
    mail_using_generic_template(:to => attendee.email, :subject => "Thanks for RSVPing to the \"#{event.name}\" event.")
  end

  def someone_is_attending_your_event_email(event, attendee)
    pre_process_body!(event, GetTogetherEmailTemplates::SOMEONE_IS_ATTENDING, event.host)
    mail_using_generic_template(:to => event.host.email, :subject => "A GetUp! member just registered to your \"#{event.name}\" event.")
  end

  def someone_canceled_their_attendance_email(event, attendee, reason=nil)
    pre_process_body!(event, replace_tokens(GetTogetherEmailTemplates::SOMEONE_CANCELED_THEIR_ATTENDANCE, "REASON" => reason), event.host)
    mail_using_generic_template(:to => event.host.email, :subject => "A GetUp! member has just cancelled attendance to your event \"#{event.name}\".")
  end

  def attendance_canceled_confirmation_email(event, attendee)
    pre_process_body!(event, GetTogetherEmailTemplates::ATTENDANCE_CANCELED_CONFIRMATION, attendee)
    mail_using_generic_template(:to => attendee.email, :subject => "Your attendance of the \"#{event.name}\" event has been cancelled.")
  end

  def pre_process_body!(event, body, recipient)
    @body_text = {}
    processed_body = pre_process(event, body, recipient.greeting)
    @body_text[:html] = processed_body
    @body_text[:text] = Nokogiri::HTML::DocumentFragment.parse(processed_body).text
  end
  private :pre_process_body!

  def pre_process(event, body, recipient_name)
    replace_tokens(body,
                   "NAME" => recipient_name,
                   "EVENT_LINK" => %Q{<a href="#{event_url(event.friendly_id)}">#{event_url(event.friendly_id)}</a>},
                   "EVENT_NAME" => event.name,
                   "EVENT_DATE" => I18n.localize(event.date),
                   "EVENT_TIME" => event.time_str,
                   "EVENT_ADDRESS" => event.address,
                   "EVENT_HOST_NOTES" => event.host_notes,
                   "EVENT_NUMBER_ATTENDEES" => event.number_of_attendees.to_s,
                   "EVENT_CAPACITY" => event.capacity.to_s
    )
  end
  private :pre_process

  def event_canceled_confirmation_email(event)
    @event = event
    mail(:to => event.host.email,
         :subject => "Your event has been cancelled!")
  end

  def event_canceled_attendees_notification_email(event)
    email_all_attendees event, "The event you have RSVP'd to has been cancelled!"
  end

  def event_changed_attendees_notification_email(event)
    email_all_attendees event, "The GetUp! event you RSVP'd to has been changed"
  end

  def message_attendees_email(event, message)
    attendees = event.attendees.map(&:email)

    if attendees.present?
      options = {:to => 'does-not-matter@getup.org.au',
                 :from => event.host.email,
                 :subject => "The host of your GetUp! \"#{event.name}\" event has sent you a message."}

      headers['X-SMTPAPI'] = to_json_for_sendgrid({to: reject_unsafe_email_addresses(attendees)})
      mail(options) do |format|
        format.text { render :text => message }
      end
    end
  end

  def email_all_attendees(event, subject)
    @event = event
    attendees = event.attendees.map(&:email)
    mail(:bcc => attendees, :subject => subject) unless attendees.blank?
  end
  private :email_all_attendees
end
