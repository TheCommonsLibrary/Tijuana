Feature: Manage events
  In order notify attendees of my inability to host an event
  As an administrator
  I want to manage events

Background: 
  Given I run the seed task
  And a user "Tom" "Mann" with email "tom.mann@example.com"
  And a user "Darth" "Vader" with email "darth.vader@example.com"
  And there is a "confirmed" upcoming Event "The Happy Kitten Event" for the Get Together "Adopt a kitten GetTogether" hosted by "tom.mann@example.com"
  And "darth.vader@example.com" is attending the "The Happy Kitten Event" event

Scenario: Admin wants to see a list of events
  Given I am logged in as an admin
  When I visit the "Forestry" campaign page
  And I click "Manage Get Together" for the "Adopt a kitten GetTogether" Get Together
  Then I should be on the admin get together page for "Adopt a kitten GetTogether"
  And I should see "The Happy Kitten Event"

Scenario: Admin wants to search events
  Given I am logged in as an admin
  When I visit the "Forestry" campaign page
  And I click "Manage Get Together" for the "Adopt a kitten GetTogether" Get Together
  Then I should be on the admin get together page for "Adopt a kitten GetTogether"
  When I fill in "query" with "Happy Kitten" 
  And I press "Search"
  Then I should see "The Happy Kitten Event"

