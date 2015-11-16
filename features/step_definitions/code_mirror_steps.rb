When /^(?:|I )replace "([^"]*)" with "([^"]*)"$/ do |original_text, replacement_text|
  id = page.execute_script("return $.find(\"textarea:contains('#{original_text}')\")[0].id")
  page.execute_script("$('##{id}').data('codeMirror').setValue('#{replacement_text}')")
end

When /^(?:|And )the field with "([^"]*)" should be disabled$/ do |field_value|
  id = page.execute_script("return $.find(\"textarea:contains('#{field_value}')\")[0].id")
  disabled = page.execute_script("return $('##{id}').data('codeMirror').getOption('readOnly')")
  disabled.should be_truthy
end

When /^(?:|I )fill in the textarea with "([^"]*)" inside the container "([^"]*)"$/ do |content, container|
  layout_selector = "\"##{container.downcase.gsub(" ", "_")}\""
  id = page.execute_script("return $(#{layout_selector}).find('textarea')[0].id")
  page.execute_script("$('##{id}').data('codeMirror').setValue('#{content}')")
end

When /^(?:|I )should see a textarea with "([^"]*)"$/ do |content|
  id = page.execute_script("return $.find(\"textarea:contains('#{content}')\")[0].id")
  content.should == page.execute_script("return $('##{id}').data('codeMirror').getValue()")
end
