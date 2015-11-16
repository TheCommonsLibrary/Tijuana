@admin, @search
Feature: Managing users
  In order to control access to the website
  As an admin
  I want to manage users of the system

Background:
  Given I run the seed task
  Given I am logged in as an admin
  Given I have a sample set of users
  
@randomlyfailingwip 
Scenario: View list of users (fails intermittently)
  Given I am on the admin users page
  Then I should see "65 in total"

#fails intermittently
@randomlyfailingwip
Scenario: Search user on email address
  Given I am on the admin users page
  Then I fill in "query" with "getup1@getup.org.au"
  Then I press "Search"
  Then I should see "1 user"

#fails intermittently
@randomlyfailingwip
Scenario: Search users on first name
  Given I am on the admin users page
  Then I fill in "query" with "first_name5"
  Then I press "Search"
  Then I should see "1 user"

@randomlyfailingwip
Scenario: Search users on last name
  Given I am on the admin users page
  Then I fill in "query" with "last_name10"
  Then I press "Search"
  Then I should see "1 user"
  
@randomlyfailingwip
Scenario: Search users on member id
  Given I am on the admin users page
  Then I fill in "query" with the member id of "chrisanthemum@example.com"
  Then I press "Search"
  Then I should see details for "chrisanthemum@example.com"

@randomlyfailingwip
Scenario: Search users on full name
  Given I am on the admin users page
  When I fill in "query" with "Chris Anthemum"
  And I press "Search"
  Then I should see "1 user"
  And I should see "Chris Anthemum"

@randomlyfailingwip
Scenario: Show only admin users
  Given I am on the admin users page
  Then I fill in "query" with ""
  And I check "admins_only"
  Then I press "Search"
  Then I should see "21 in total"

@randomlyfailingwip
Scenario: Create a user with valid details
  Given I am on the admin users page
  Then I follow "Create new user"
  Then I should be on the new admin user page
  Then I fill in "user_email" with "colonelbobson@shangrila.com"
  And I check "user[is_admin]"
  Then I press "Create user"
  Then I should be on the admin users page
  And I should see "66 in total"
  Then I check "admins_only"
  And I press "Search"
  Then I should see "22 in total"

Scenario: Create a user with invalid details
  Given I am on the admin users page
  Then I follow "Create new user"
  Then I should be on the new admin user page
  Then I fill in "user_first_name" with "Roger"
  Then I fill in "user_last_name" with "Simonson"
  And I check "user[is_admin]"
  Then I press "Create user"
  Then I should see "New User"
  
Scenario: Creating a user and cancelling before saving
  Given I am on the admin users page
  Then I follow "Create new user"
  Then I should be on the new admin user page
  Then I fill in "user_email" with "colonelbobson@shangrila.com"
  Then I follow "Cancel"
  Then I should be on the admin users page

Scenario: Editing the details of a user
  Given I am on the edit admin user page for "getup1@getup.org.au"
  Then I fill in "user_email" with "rogerdodgder@helloworld.gov.ch"
  And I fill in "user_first_name" with "Gherkin"
  And I fill in "user_last_name" with "Clock"
  And I check "user[is_admin]"
  Then I press "Save user"
  Given I am on the admin users page
  Then I fill in "query" with "rogerdodgder@helloworld.gov.ch"
  And I check "admins_only"
  And I press "Search"
  Then I should see "1 user"
  And I should see "Gherkin Clock"

Scenario: Not delete my own account
  Given I am on the edit admin user page for "theadminuser@getup.org.au"
  Then I should not see "Delete user"

Scenario: Remove the membership status of a user
  Given I am on the edit admin user page for "getup1@getup.org.au"
  Then the "user[is_member]" checkbox should not be checked
  Then I check "user[is_member]"
  Then I press "Save user"
  Given I am on the edit admin user page for "getup1@getup.org.au"
  Then the "user[is_member]" checkbox should be checked
