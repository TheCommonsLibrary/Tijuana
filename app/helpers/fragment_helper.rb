module FragmentHelper
  include FormattingHelper

  def add_tracking_hash_to_links(text, user, email, recipients_for_test)
    rewrite_links(text, "t=#{set_token(user, email, recipients_for_test)}")
  end

  def set_token(user, email, recipients_for_test)
    recipients_for_test ? "NOT_AVAILABLE" : EmailTrackingToken.encode(user.id, email.id)
  end

  def rewrite_links(text, token)
    text.gsub(Email::URL_REGEX_HTML) do |match|
      match.index('?') ? "#{match}&#{token}" : "#{match}?#{token}"
    end
  end

  def format_event_date_time(event)
    "#{pretty_time(event.time, event.date)}, #{event.date.strftime("%e %B %Y")}"
  end
end
