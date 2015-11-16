Feature: Find Get Together Events
  In order to attend a Get Together event 
  As a user
  I want to find an event

Background:
  Given I run the seed task
  And a user "Tom" "Mann" with email "tom.mann@example.com"

@wip @javascript
Scenario: View a list of events for a Get Together
  Given the event "The Happy Kitten Event" is located in postcode "2000"
  And I am on the "Adopt a kitten GetTogether" get together page
  When I follow "List"
  Then "The Happy Kitten Event" should be visible
  When I fill in "postcode" with "2046"
  And I press "Filter"
  Then "The Happy Kitten Event" should not be visible
  When I fill in "postcode" with "2000"
  And I press "Filter"
  Then "The Happy Kitten Event" should be visible
  When I fill in "postcode" with "2046"
  And I press "Filter"
  Then "The Happy Kitten Event" should not be visible
  When I follow "remove filter"
  Then "The Happy Kitten Event" should be visible
