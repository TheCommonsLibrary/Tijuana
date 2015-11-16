And /^I click "([^\"]*)"$/ do |selector|
  find(selector).click
end

When /^I select "([^\"]*)" as the "(\d*).{2}" filter type$/ do |value, position|
  find(:xpath, "//fieldset/ul/li[#{position}]/span/select").select(value)
end