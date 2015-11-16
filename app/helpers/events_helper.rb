module EventsHelper
  include FormattingHelper
  
  def can_be_attended?(event, current_user)
    ((current_user.blank? || !event.has_attendee?(current_user)) &&
        event.status == 'open' && !event.has_host?(current_user))
  end

  def can_be_changed?(event)
    !['canceled', 'ended'].include?(event.status)
  end

  def should_display_attendees?(event)
    (!['canceled', 'unconfirmed'].include?(event.status)) && event.capacity.present? && event.capacity < 20
  end

  def if_less_than(s, len)
    if s.length < len
      "'#{s}'"
    else
      ""
    end
  end

  def sum(events, property)
    events.reduce(0) {|sum, event| sum + event.send(property.to_sym).size }
  end

  def event_hour_formatted(time)
    time.to_s.rjust(4,'0')[0,2]
  end

  def event_minute_formatted(time)
    time.to_s.rjust(4,'0')[2,4]
  end

  def formatted_time(time)
    "#{time.to_s.rjust(4,'0')[0,2]}:#{time.to_s.rjust(4,'0')[2,4]}"
  end
  
  def pretty_distance(distance)
    if (distance > 1)
      distance.round(1).to_s + "km"
    else
      (distance*1000).to_i.to_s + "m"
    end  
  end
  
  def display_date(date)
    if date.is_a? Hash
      date[:from_date].strftime("%A #{date[:from_date].day.ordinalize} %B %Y") + " through " + date[:to_date].strftime("%A #{date[:to_date].day.ordinalize} %B %Y")
    else
      date.strftime("%A #{date.day.ordinalize} %B %Y")
    end
  end

  def date_within_three_months?(date)
    time_of_event = Time.parse(date.to_s)
    Time.now <= time_of_event.advance(:months => 3)
  end
end
