Feature: User Activity Events
  In order to demonstrate activity on the site
  As a user
  I want to see that other people are taking action

Background:
  Given I run the seed task

@javascript
Scenario: Taking action
  Given a user "Fred" "Smith" with email "fred@example.com"
  When I visit the "Landing Page for Gunns Petition" page
  And I fill in email with "fred@example.com" and wait for lookup
  And I press "Sign the petition!"
  When I am on the home page
  Then I should see "Fred added their signature to a petition"

@javascript @randomlyfailingwip
Scenario: Taking action and subscribing to GetUp!
  Given I am logged in as an admin
  When I visit the "Landing Page for Gunns Petition" page
  And I fill in email with "fred@example.com" and wait for lookup
  And I fill in "user_first_name" with "Fred"
  And I should see "Receive GetUp! updates"
  And the "user_is_member" checkbox should be checked
  And I press "Sign the petition!"
  When I am on the edit admin user page for "fred@example.com"
  Then I should see "Fred added their signature to a petition"
  And I should see "Fred subscribed to GetUp!"
  
@javascript @randomlyfailingwip
Scenario: Taking action and not subscribing to GetUp!
  Given I am logged in as an admin
  When I visit the "Landing Page for Gunns Petition" page
  And I fill in "user_email" with "fred1@example.com"
  And I fill in "user_first_name" with "Fred"
  And I should see "Receive GetUp! updates"
  And I uncheck "user_is_member"
  Then the "user_is_member" checkbox should not be checked
  And I press "Sign the petition!"
  When I am on the edit admin user page for "fred1@example.com"
  Then I should see "Fred added their signature to a petition"
  And I should not see "Fred subscribed to GetUp!"
 
@javascript
Scenario: Attending an event
  Given a user "Fred" "Smith" with email "fred@example.com"
  When I am on the "The Happy Kitten Event" event page
  And I fill in email with "fred@example.com" and wait for lookup
  And I fill in "user_mobile_number" with "041212121212"
  And I press "Sign Up"
  Then I should be on the "The Happy Kitten Event" event page
  When I am on the homepage
  Then I should see "Fred is attending The Happy Kitten Event"
 
