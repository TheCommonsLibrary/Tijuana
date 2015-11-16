Given /^there is an upcoming Get Together "([^"]*)"$/ do |get_together_name|
  create(:get_together, {:from_date => Time.now+18.days, :to_date => Time.now+20.days, :name => get_together_name})
end

Given /^there is a past Get Together "([^"]*)"$/ do |get_together_name|
  create(:get_together, {:from_date => Time.now-22.days, :to_date => Time.now-20.days, :name => get_together_name})
end

When /^there is a "([^\"]*)" upcoming Event "([^\"]*)" for the Get Together "([^\"]*)" hosted by "([^\"]*)"$/ do |event_status, event_name, get_together_name, host_email|
  host = User.find_by_email(host_email)
  get_together = create(:get_together, {:from_date => Date.today + 18, :to_date => Date.today + 22, :name => get_together_name})
  case event_status
    when /confirmed/
      create(:event, :name => event_name, :date => Date.today + 19, :time => 700, :get_together => get_together, :host => host,
        :confirmed_at => DateTime.now)
    when /canceled/
      create(:event, :name => event_name, :date => Date.today + 19, :time => 700, :get_together => get_together, :host => host,
        :confirmed_at => DateTime.now, :canceled_at => DateTime.now)
  end
end

When /^"([^\"]*)" is attending the "([^\"]*)" event$/ do |email, event_name|
  event = Event.find_by_name(event_name)
  user = User.find_by_email(email)
  event.add_attendee!(user)
end

When /^I visit the event "([^\"]*)" page$/ do |event_name|
  event = Event.find_by_name(event_name)
  event.should_not be_nil
  visit event_path(event.friendly_id)
end

When /^there is a comment for the "([^\"]*)" event posted by "([^\"]*)"$/ do |event_name, comment_author|
  event = Event.find_by_name(event_name)
  Comment.build_from(event, User.find_by_email(comment_author).id, "Existing comment").save!
end
