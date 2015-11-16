Feature: Host sends messages to attendees
  In order to communicate important information about my event
  As a host
  I want to send message to all attendees

Background:
  Given I run the seed task
  And a user "Tom" "Mann" with email "tom.mann@example.com"
  And a user "Darth" "Vader" with email "darth.vader@example.com"
  And there is a "confirmed" upcoming Event "Tom's Event" for the Get Together "Save the Dolphins" hosted by "tom.mann@example.com"
  And "darth.vader@example.com" is attending the "Tom's Event" event
  And there is a "confirmed" upcoming Event "Empty Event" for the Get Together "No one likes us" hosted by "tom.mann@example.com"

@javascript
Scenario: Host sends message to attendees
  Given I am logged in as "tom.mann@example.com"
  And I am on the "Tom's Event" event page
  And I fill in "message" with "Don't come! It's a trap!"
  And I press "Send Message"
  Then I should be on the "Tom's Event" event page
  And I should see "Your message is in the process of being sent."

@javascript
Scenario: Host attempts to send a message to an event with no attendees
  Given I am logged in as "tom.mann@example.com"
  And I am on the "Empty Event" event page
  Then I should not see "message" within "#action .sidebar"
  And I should not see "Send message"
