def tracking_data(email_address, email_name)
  user = User.find_by_email(email_address)
  user.should_not be_nil
  email = Email.find_by_name(email_name)
  email.should_not be_nil
  t = EmailTrackingToken.encode(user.id, email.id)
end

Then /^show me the last email for "([^"]*)"$/ do|address|
  open_email(address)
  y current_email.header.inspect
  y current_email.default_part_body.inspect
end

Given /^I visit the admin push page for "([^"]*)"$/ do |name|
  push = Push.find_by_name(name)
  push.should_not be_nil
  visit admin_push_path(push)
end

When /^"([^"]*)" opens the email "([^"]*)"$/ do |email_address, email_name|
  t = tracking_data(email_address, email_name)
  visit "/beacon.gif?t=#{t}"
end

When /^"([^"]*)" visits the "([^"]*)" page from the email "([^"]*)"$/ do |email_address, page_name, email_name|
  page = Page.find_by_name(page_name)
  page.should_not be_nil
  t = tracking_data(email_address, email_name)
  visit page_path(page.page_sequence.campaign, page.page_sequence, page, :t => t)
end

When /^"([^"]*)" visits the unsubscribe me page from the email "([^"]*)"$/ do |email_address, email_name|
  t = tracking_data(email_address, email_name)
  visit unsubscribe_path(:t => t)
end

Then /^I should see the following statistics for the email "([^"]*)":$/ do |email_name, stats|
  email = Email.find_by_name(email_name)
  email.should_not be_nil
  tr_selector = "//td[text()=\"#{email_name}\"]/.."
  within(:xpath, tr_selector) do
    stats.hashes.first.each do |header, value|
      actual_value = page.find("td.#{header.downcase.gsub(' ', '-')}").text
      raise "Expected #{value} #{header} but was #{actual_value}" if actual_value != value
    end
  end
end

# stub job processing visibility for view purposes
When /^blasts are queued for delivery indefinitely$/ do
  Email.class_eval do
    alias_method :old_delayed_job_id, :delayed_job_id
    def delayed_job_id
      999
    end
  end

  Blast.class_eval do
    alias_method :old_has_pending_jobs?, :has_pending_jobs?
    def has_pending_jobs?
      true
    end
  end
end

When /^blasts are processed again$/ do
  Email.class_eval do
    alias_method :delayed_job_id, :old_delayed_job_id
    remove_method :old_delayed_job_id
  end

  Blast.class_eval do
    alias_method :has_pending_jobs?, :old_has_pending_jobs?
    remove_method :old_has_pending_jobs?
  end
end

Then /^I should see the "(.*?)" button on the page$/ do |button|
  has_button?(button)
end

Given /^I refresh the push stats$/ do
  click_on("Refresh Statistics")
end
