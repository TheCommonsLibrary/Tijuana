Feature: Cancel attendance to an event
  In order to prevent frustration
  As an attendee
  I want to cancel my attendance to an event

Background: 
  Given I run the seed task
  And a user "Tom" "Mann" with email "tom.mann@example.com"
  And a user "Darth" "Vader" with email "darth.vader@example.com"
  And there is a "confirmed" upcoming Event "Tom's Event" for the Get Together "Save the Dolphins" hosted by "tom.mann@example.com"
  And "darth.vader@example.com" is attending the "Tom's Event" event

@javascript
Scenario: Attendee cancels his attendance
  Given I am logged in as "darth.vader@example.com"
  And I am on the "Tom's Event" event page
  When I follow "No" within "#attendee-status"
  Then I should be on the "Tom's Event" event page
  And I should see "Your attendance to this event has been canceled."
