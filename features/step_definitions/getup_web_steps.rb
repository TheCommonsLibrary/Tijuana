require 'uri'

# Testing modal window
When /^I click "([^"]*)" after following "([^"]*)"$/ do |action, link|
  prepare_dialog_box(action)
  click_link(link)
end

When /^I click "([^"]*)" after pressing "([^"]*)"$/ do |action, link|
  prepare_dialog_box(action)
  click_button(link)
end

Then /^the request protocol should be "(\w*)"/ do |protocol|
  uri = URI.parse(current_url)
  assert(protocol == uri.scheme, "Wrong protocol - expected #{protocol}, was #{uri.scheme}")
end

Given /^I wait ([0-9\.]+) seconds$/ do |seconds|
  sleep(seconds.to_f)
end

Then /^I should (not )?see an element "([^"]*)"$/ do |negate, selector|
  expectation = negate ? :should_not : :should
  page.send(expectation, have_css(selector))
end

Then /^"([^\"]+)" should (not )?be visible$/ do |text, negate|
  paths = [
           "//*[@class='hidden']/*[contains(.,'#{text}')]",
           "//*[@class='invisible']/*[contains(.,'#{text}')]",
           "//*[@style='display: none;']/*[contains(.,'#{text}')]"
          ]
  xpath = paths.join '|'
  if negate
    page.should have_xpath(xpath)
  else
    page.should_not have_xpath(xpath)
  end
end

Then /^the "([^\"]*)" field should be disabled$/ do |label|
  find_field(label, :visible => false, :disabled => true)
end


Then /^the "([^\"]*)" field should not be disabled$/ do |label|
  find_field(label, :visible => false)
end

When /^I wait until I can see "([^"]*)"$/ do |selector|
  page.has_css?("#{selector}", :visible => true)
end

When /^I wait until I can read "([^"]*)"$/ do |content|
  page.has_content?(content)
end

When /^I visit the URL "([^"]*)"$/ do |url|
  visit url
end

When /^I fill in "([^"]*)" with tomorrow$/ do |selector|
  date = Date.tomorrow.strftime "%d-%m-%Y"
  fill_in(selector, :with => date)
end

When /^I fill in email with "([^"]*)" and wait for lookup$/ do |value|
  fill_in('user_email', :with => value)
  wait_until(3) { page.find(".user-lookup-message").visible? }
end


Then /^There should be "([^"]*)" only once inside (.*[^:])$/ do |elem, selector|
  with_scope(selector) do
    if page.respond_to? :should
      page.should have_css(elem, :count => 1)
    else
      assert page.has_css?(elem, :count => 1)
    end
  end
end

Then /^I set my jobs to work$/ do
  sleep 1 # needed to wait for list cutter job to appear?
  Delayed::Worker.new.work_off
end
