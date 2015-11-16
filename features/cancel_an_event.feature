Feature: Cancel an Event
  In order notify attendees of my inability to host an event
  As the event host
  I want to cancel my event

Background: 
  Given I run the seed task
  And a user "Tom" "Mann" with email "tom.mann@example.com"
  And there is a "confirmed" upcoming Event "Tom's Event" for the Get Together "Save the Dolphins" hosted by "tom.mann@example.com"
  And there is a "canceled" upcoming Event "Canceled Event" for the Get Together "Save the Dolphins" hosted by "tom.mann@example.com"


@javascript @wip
Scenario: Host cancels an event
  Given I am logged in as "tom.mann@example.com"
  When I visit the event "Tom's Event" page
  Then I should be on the "Tom's Event" event page
  When I follow "Edit Event"
  And I click "OK" after following "Cancel Event"
  Then I should be on the "Tom's Event" event page
  And I should see "Your event has been canceled"
  And I should not see "Edit Event"

Scenario: Host tries to cancel an already canceled event
  Given I am logged in as "tom.mann@example.com"
  When I visit the event "Canceled Event" page
  Then I should be on the "Canceled Event" event page
  And I should not see "Cancel event"
  And I should not see "Attending this event"
  And I should see "This event has been cancelled"

Scenario: User tries to cancel an event
  Given a "normal user" with email "normal@user.com"
  And I am logged in as "normal@user.com"
  And I visit the event "Tom's Event" page
  Then I should be on the "Tom's Event" event page
  And I should not see "Cancel event"  
