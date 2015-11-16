@admin @without_transactional_fixtures @no-database-cleaner
Feature: Creating a push for a campaign
  In order to inform users that their assistance is required
  As a campaigner
  I want to create pushes encouraging them to take action on a campaign

Background:
  Given I run the seed task
  And I am logged in as an admin

@javascript @delayed-jobs
Scenario: Campaigner sends a blast and cancels it
  Given there are 10 members in the system
  And there is a push "Climate action" for the "Forestry" campaign
  And there is a blast "Save the polar bears" for the "Climate action" push
  And there is an email "The ice age cometh" for the "Save the polar bears" blast
  And I am on the admin push page for "Climate action"
  Then I should see "Save the polar bears"
  When I follow "Cut a list"
  Then I should be on the new list page
  When I press "Show count"
  Then I set my jobs to work
  And I should see "FOUND 10 MEMBERS" within "#list-cutter-results"
  When I press "Save"
  Then I set my jobs to work
  And I wait until I can read "Save the polar bears"
  And I should see "Edit List"
  When I follow "The ice age cometh"
  And I fill in "Recipients" with "this.is.not.a.user@getup.org.au"
  And I press "Send"
  Then I set my jobs to work
  And I should be on the admin push page for "Climate action"
  And I should see "Proof queued"
  And I should see "Deliver" within "#blasts-list"
  When I fill in "limit" with "5"
  And I press "Send"
  Then I should be on the admin push page for "Climate action"
  And There should be ".in-progress" only once inside "#blasts-list"
  And I should see "Delivery in"
  When I click "OK" after following "undo"
  Then I should be on the admin push page for "Climate action"
  And I should see "Delivery cancelled"

@javascript
Scenario: Adding notes to pushes
  Given there is a push "Climate action" for the "Forestry" campaign
  And I am on the admin push page for "Climate action"
  Then I should see "Click here to edit"
  When I click ".notes-body"
  And I fill in "note" with "This is my note"
  When I press "Save"
  Then I should see "This is my note"
