@wip
Feature: Create an event
  In order to notify other GetUp! members of my event 
  As a user
  I want to list my event on the GetUp!

Background: 
  Given I run the seed task
  And a user "Tom" "Mann" with email "tom.mann@example.com"

Scenario: Navigate through to event creation
  Given I am on the Get Togethers page
  When I follow "Adopt a kitten GetTogether"
  Then I should see "Create Event"

@javascript @wip
Scenario: Create an event
  Given I am logged in as "tom.mann@example.com"
  And I am on the "Adopt a kitten GetTogether" get together page
  When I follow "Create Event"
  Then I should see "New event"
  And I should see "Event location"
  When I fill in "event[address]" with "Sydney"
  And I press "lookup address"
  And I select the first address returned
  And I press "Next >>"
  Then I should see "Event details"
  And the "user[email]" field should contain "tom.mann@example.com"
  When I fill in the following:
    | event[name]     | Mann up at Tom's place |
    | event[phone]    |                2222222 |
    | event[capacity] |                     12 |
  And I select "12" from "event_hour"
  And I select "15" from "event_minute"
  And I press "Next >>"
  And I accept the terms and conditions
  And I press "Create Event"
  Then I should see "Event has been created"
  And I should see "This event is not confirmed yet. If you are the host, please refer to the confirmation email you received regarding this event."

@javascript @wip
Scenario: Admin creates event for user without confirmation
  Given I am logged in as an admin
  And I am on the "Adopt a kitten GetTogether" get together page
  When I follow "Create Event"
  Then I should see "New event"
  And I should see "Event location"
  When I fill in "event[address]" with "Sydney"
  And I press "lookup address"
  And I select the first address returned
  And I press "Next >>"
  Then I should see "Event details"
  When I fill in the following:
    | event[name]     | Mann up at Tom's place |
    | event[phone]    |                2222222 |
    | event[capacity] |                     12 |
    | user[email]     | sally.mann@example.com |
  And I select "12" from "event_hour"
  And I select "15" from "event_minute"
  And I press "Next >>"
  And I accept the terms and conditions
  And I press "Create Event"
  Then I should see "Event has been created"
  And I should not see "This event is not confirmed yet."

@javascript  
Scenario: User attends an event
  Given I am on the "The Happy Kitten Event" event page
  And I fill in "user[email]" with "theattendee@party.com"
  And I press "Attend"
  Then I should be on the "The Happy Kitten Event" event page
  Then I should see "Thanks for attending this event! You will receive an email shortly with everything you need to know!"

@javascript   
Scenario: Event is full
  Given I am on the "Full Event" event page
  Then I should see "Sorry, this event is full"
  And I should not see "Attend" within "#attend-this-event"

Scenario: User wants to share event
  Given I am on the "The Happy Kitten Event" event page
  Then I should see "Send this via Email"
