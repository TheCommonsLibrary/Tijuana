Given /^the following users are attending "([^"]*)":$/ do |event_name, attendees_table|
  event = Event.find_by_name(event_name)
  attendees_table.hashes.each do |hash| 
    event.add_attendee!(User.new(:first_name => hash[:name], :email => hash[:email]))
  end
end

Then /^I should see all the attendees to "([^"]*)"$/ do |event_name|
  event = Event.find_by_name(event_name)
  event.attendees.each do |attendee|
    if page.respond_to? :should
      page.should have_content(attendee[:first_name])
    else
      assert page.has_content?(attendee[:first_name])
    end
  end
end

When /^I click "([^"]*)" for the "([^"]*)" Get Together$/ do |action, get_together|
  with_scope("\"#get-together-#{GetTogether.find_by_name(get_together).id}\"") do
    click_link(action)
  end
end

When /^I select the first address returned$/ do
  find("ul.map-addresses li:first-child a").click
end

Given /^the event "([^"]*)" is located in postcode "([^"]*)"$/ do |event_name, postcode|
  event = Event.find_by_name event_name
  event.update_attribute :postcode, postcode
end
When /^I accept the terms and conditions$/ do
  check("event_terms_and_conditions")
end