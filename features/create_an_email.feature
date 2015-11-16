@javascript @admin @without_transactional_fixtures @no-database-cleaner
Feature: Creating an email for a campaign
  In order to inform users that their assistance is required
  As a campaigner
  I want to create emails encouraging them to take action on a campaign

Background:
  Given I run the seed task
  And a default Email
  And I am logged in as an admin

Scenario: Creating an email
  When I visit the "Forestry" campaign page
  And I follow "Email everyone to save the trees"
  And I follow "Add an email"
  And I fill in "Name" with "Call for donations"
  And I fill in "Subject" with "We need your help!"
  And I fill in "From name" with "GetUp!"
  And I fill in "From address" with "campaigns@getup.org.au"
  And I fill in "Reply to address" with "no-reply@getup.org.au"
  When I press "Create email"
  Then I should see "Body can't be blank"
  When I author "Body" with "Please follow the link and take action."
  And I press "Create email"
  Then I should be on the admin push page for "Email everyone to save the trees"
  And I should see "Call for donations" within ".emails"

Scenario: Send an email for proof
  Given there is an email "Test Email" for the "Forestry" campaign
  When I visit the "Forestry" campaign page
  And I follow "Push for Test Email"
  And I follow "Test Email"
  And I fill in "Subject" with "This is a test"
  And I fill in "Recipients" with "cucumber@getup.org.au"
  And I press "send-test"
  Then "does-not-matter@getup.org.au" should receive an email with subject "This is a test"
  And I should see "Proof queued"

