Given /^I visit the "([^"]*)" page sequence page$/ do |name|
  sequence = PageSequence.find_by_name(name)
  sequence.should_not be_nil
  visit admin_page_sequence_path(sequence, {:bare => nil})
end

Given /^I visit the "([^"]*)" page$/ do |name|
  page = Page.find_by_name(name)
  page.should_not be_nil
  visit page_path(page.page_sequence.campaign, page.page_sequence, page)
end

Given /^I visit the admin "([^"]*)" page$/ do |name|
  page = Page.find_by_name(name)
  page.should_not be_nil
  visit edit_admin_page_path(page)
end

When /^I follow "([^"]*)" for "([^"]*)" page sequence$/ do |link_name, sequence_name|
  page_sequence = PageSequence.find_by_name(sequence_name)
  selector = "\"#page-sequence-#{page_sequence.id}\""
  with_scope(selector) do
    click_link(link_name)
  end
end

Then /"(.*)" should appear before "(.*)"/ do |first_example, second_example|
  page.body.should =~ /#{first_example}.*#{second_example}/m
end

# Testing modal window
When /^(?:|I )follow "([^"]*)"(?: for the page sequence "([^"]*)")? and click "([^"]*)"$/ do |link, name, action|
  pageSequence = PageSequence.find_by_name(name)
  pageSequence.should_not be_nil
  selector = "#page-sequence-#{pageSequence.id}"
  with_scope(selector) do
    prepare_dialog_box(action)
    click_link(link)
  end
end

When /^(?:|I )follow "([^"]*)"(?: for the page "([^"]*)")? and click "([^"]*)"$/ do |link, name, action|
  page = Page.find_by_name(name)
  page.should_not be_nil
  selector = "#page_#{page.id}"
  with_scope(selector) do
    prepare_dialog_box(action)
    click_link(link)
  end
end

Given /^a campaign page entitled "([^"]*)" with required (.*)$/ do |page_name, user_detail|
  create(:page, :name => page_name, :required_user_details => {user_detail => :required})
end

Given /^a campaign page entitled "([^"]*)"$/ do |page_name|
  create(:page, :name => page_name)
end