@admin
Feature: Managing GetTogethers
  In order allow events to be hosted
  As a admin/campaigner
  I want to create GetTogether for campaigns

Background:
  Given I run the seed task
  Given I am logged in as an admin

Scenario: View list of get togethers
  When I visit the "Forestry" campaign page
  Then I should see "Forestry"
  And I should see "Get Togethers"
  And I should see "Adopt a kitten GetTogether"

Scenario: Add a Get Together
  When I visit the "Forestry" campaign page
  And I follow "Add a Get Together"
  Then I should be on the new admin get together page

  When I press "Create Get Together"
  And I should see "Name can't be blank"
  And I should see "Description can't be blank"
  And I should see "Content can't be blank"

  When I fill in "Name" with "We are Motorhead! Come and have some free beers!"
  And I fill in "get_together_description" with "You can't miss this! It's the legend in flesh & bones!"
  And I fill in "get_together_content_module_attributes_content" with "<strong>This is awesome</strong>"
  And I fill in "get_together_from_date" with "24-03-2011"
  And I fill in "get_together_to_date" with "24-03-2011"
  And I fill in "Recommended date" with "24-03-2011"
  And I fill in "Host greeting email" with "Hello! {NAME|Friend}"
  And I fill in "Attendee greeting email" with "Hello! {NAME|Friend}"
  And I select "17:00" from "get_together_from_time"
  And I select "20:00" from "get_together_to_time"
  And I select "18:00" from "Recommended time"
  And I press "Create Get Together"
  Then I should be on the admin campaign page for "Forestry"
  And I should see "We are Motorhead! Come and have some free beers!"

@javascript
Scenario: Editing a Get Together
  When I visit the "Forestry" campaign page
  And I follow "Adopt a kitten GetTogether"
  And I follow "Edit details"
  When I fill in "Name" with "We are Motorhead! Come and have some free beers!"
  And I fill in "Description" with "You can't miss this! It's the legend in flesh & bones!"
  And I fill in "get_together_event_content_html" with "<strong>This is awesome</strong>" inside the xpath "//fieldset[legend/text()='Public Event View']"
  And I fill in "get_together_from_date" with "24-03-2011"
  And I fill in "get_together_to_date" with "24-03-2011"
  And I fill in "Recommended date" with "24-03-2011"
  And I fill in "get_together_host_greeting_email" with "Hello! {NAME|Friend}"
  And I fill in "get_together_attendee_greeting_email" with "Hello! {NAME|Friend}"
  And I select "17:00" from "get_together_from_time"
  And I select "20:00" from "get_together_to_time"
  And I select "18:00" from "Recommended time"
  And I press "Save Get Together"
  Then I should be on the admin campaign page for "Forestry"
  And I should see "'We are Motorhead! Come and have some free beers!' has been saved"

@javascript
Scenario: Deleting a Get Together
  When I visit the "Forestry" campaign page
  And I follow "Adopt a kitten GetTogether"
  And I click "Cancel" after following "Delete Get Together"
  Then I should not see "'Adopt a kitten GetTogether' has been deleted"
  When I click "OK" after following "Delete Get Together"
  Then I should see "'Adopt a kitten GetTogether' has been deleted"
  And I should not see "Adopt a kitten GetTogether" within "#get-togethers-list"
