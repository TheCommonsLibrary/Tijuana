@wip
Feature: Manage event attendees
  In order to have control over my event
  As the event host
  I want to manage people attending

Background: 
  Given I run the seed task
  And a user "Tom" "Mann" with email "tom.mann@example.com"
  And there is a "confirmed" upcoming Event "Tom's Event" for the Get Together "Save the Dolphins" hosted by "tom.mann@example.com"
  And there is a "canceled" upcoming Event "Canceled Event" for the Get Together "Save the Dolphins" hosted by "tom.mann@example.com"



Scenario: Host wants to see a list of attendees
  Given I am logged in as "tom.mann@example.com"
  And the following users are attending "Tom's Event":
    | name       | email                   |
    | Zaralindha | zaralindha@getup.org.au |
    | Kynthelig  | kynthelig@getup.org.au  |
    | Xiomar     | xiomar@getup.org.au     |
  When I go to the "Tom's Event" event page
  Then I should see "Attending this event"
