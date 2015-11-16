@without_transactional_fixtures @no-database-cleaner
Feature: Viewing a campaign page
  In order to take an action
  As a user
  I want to view a campaign page

Background:
  Given I run the seed task

Scenario: View a campaign page
  And I visit the "Landing Page for Gunns Petition" page
  Then I should see "Landing Page for Gunns Petition"
  And I should see "Save the kittens!"
  And I should see "No, save the walrus!"
  And I should see "I know you did not directly land from email, so I give you some information about what GetUp do"
  And I should not see "What about Narwhals?"
  Then "Save the kittens!" should appear before "No, save the walrus!"
  Then I visit the "Thankyou Page for Gunns Petition" page
  And I should not see "Landing Page for Gunns Petition"
  And I should see "What about Narwhals?"
  And I should see "Ducks are cool too!"
  And I should not see "Save the kittens!"
  Then "What about Narwhals?" should appear before "Ducks are cool too!"

Scenario: View a campaign page from email
  Given a default Email
  Given a user "Fred" "Smith" with email "fred@example.com"
  When "fred@example.com" opens the email "Forestry Campaign Email"
  And "fred@example.com" visits the "Landing Page for Gunns Petition" page from the email "Forestry Campaign Email"
  And I should not see "I know you did not directly land from email, so I give you some information about what GetUp do"





