@admin
Feature: Cutting a list for a push
  In order to easily select target members for a push
  As a campaigner
  I want to cut a list matching various criteria

Background:
  Given I run the seed task
  And a default Email
  And I am logged in as an admin

@javascript @without_transactional_fixtures @no-database-cleaner
Scenario: List cutting (incrementally replaced by scenario admin_cuts_a_list)
  When I visit the "Forestry" campaign page
  And I follow "Email everyone to save the trees"
  And I should see "Forestry Campaign Email"
  When I follow "Cut a list"
  Then I should be on the new list page
  
  And I select "Country" as the "3rd" filter type

  And I click ".add-filter"
  And I select "Domain" as the "4th" filter type
  And I fill in "rules[email_domain_rule][domain]" with "@gmail.com"

  And I click ".add-filter"
  And I select "Donation Frequency" as the "5th" filter type
  And I select "One Off" from "rules[donor_rule][frequencies][]"

  And I click ".add-filter"
  And I select "Number of Actions Taken" as the "6th" filter type
  And I fill in "rules[action_taken_rule][greater_than]" with "1"
  And I fill in "rules[action_taken_rule][page_ids]" with "eval Page.first.id"

  And I click ".add-filter"
  And I click ".add-filter"
  And I select "States and Territories" as the "7th" filter type
  And I select "New South Wales" from "rules[state_territory_rule][states_territories][]"

  And I click ".add-filter"
  And I select "Campaigns" as the "8th" filter type
  And I select "Forestry" from "rules[campaign_rule][campaigns][]"

  And I press "Show count"

  Then I should see "SQL Generated" within "#list-cutter-results"

  When I press "Save"
  Then I wait 1 seconds
  Then I should be on the admin push page for "Email everyone to save the trees"
  And I should see "Edit List"
