
Then /I fill in the action_taken_rule with the first page id/ do
  fill_in("rules[action_taken_rule][page_ids]", with: Page.first.id)
end
