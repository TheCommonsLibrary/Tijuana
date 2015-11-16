@without_transactional_fixtures @no-database-cleaner
@javascript
Feature: Monitoring email statistics
  In order to tune emails for maximum performance
  As a campaigner
  I want to view the statistics around user responses to emails

  Background:
    Given I run the seed task
    Given a default Email
    Given a user "Fred" "Smith" with email "fred@example.com"
    Given I am logged in as an admin

  Scenario: Viewing an email
    When "fred@example.com" opens the email "Forestry Campaign Email"
    And I visit the admin push page for "Email everyone to save the trees"
    Then  I should see the "Refresh Statistics" button on the page
    And I refresh the push stats
    Then I should see the following statistics for the email "Forestry Campaign Email":
      | Sent to | Opens | Clicks | Actions Taken | New Members | Unsubscribed |
      | 0       | 1     | 0      | 0             | 0           | 0            |

  Scenario: Clicking an email
    When "fred@example.com" opens the email "Forestry Campaign Email"
    And "fred@example.com" visits the "Landing Page for Gunns Petition" page from the email "Forestry Campaign Email"
    And I visit the admin push page for "Email everyone to save the trees"
    Then  I should see the "Refresh Statistics" button on the page
    And I refresh the push stats
    Then I should see the following statistics for the email "Forestry Campaign Email":
      | Sent to | Opens | Clicks | Actions Taken | New Members | Unsubscribed |
      | 0       | 1     | 1      | 0             | 0           | 0            |

  Scenario: Existing member taking action on an email
    When "fred@example.com" opens the email "Forestry Campaign Email"
    And "fred@example.com" visits the "Landing Page for Gunns Petition" page from the email "Forestry Campaign Email"
    And I fill in email with "fred@example.com" and wait for lookup
    And I press "Sign the petition!"
    Then I should see "Thankyou Page for Gunns Petition"
    When I visit the admin push page for "Email everyone to save the trees"
    Then  I should see the "Refresh Statistics" button on the page
    And I refresh the push stats
    Then I should see the following statistics for the email "Forestry Campaign Email":
      | Sent to | Opens | Clicks | Actions Taken | New Members | Unsubscribed |
      | 0       | 1     | 1      | 1             | 0           | 0            |

  Scenario: New member taking action on an email
    When "fred@example.com" opens the email "Forestry Campaign Email"
    And "fred@example.com" visits the "Landing Page for Gunns Petition" page from the email "Forestry Campaign Email"  
    And I fill in email with "someone.new@example.com" and wait for lookup
    And I fill in "user_first_name" with "Newbie"
    And I press "Sign the petition!"
    Then I should see "Thankyou Page for Gunns Petition"
    When I visit the admin push page for "Email everyone to save the trees"
    Then  I should see the "Refresh Statistics" button on the page
    And I refresh the push stats
    Then I should see the following statistics for the email "Forestry Campaign Email":
      | Sent to | Opens | Clicks | Actions Taken | New Members | Unsubscribed |
      | 0       | 1     | 1      | 1             | 1           | 0            |  

  Scenario: Member gets upset by an email and unsubscribes
    When "fred@example.com" opens the email "Forestry Campaign Email"
    And "fred@example.com" visits the unsubscribe me page from the email "Forestry Campaign Email"
    And I fill in "Email" with "fred@example.com"
    And I press "Unsubscribe"
    Then I should see "Your subscription has been successfully cancelled"
    When I visit the admin push page for "Email everyone to save the trees"
    Then  I should see the "Refresh Statistics" button on the page
    And I refresh the push stats
    Then I should see the following statistics for the email "Forestry Campaign Email":
      | Sent to | Opens | Clicks | Actions Taken | New Members | Unsubscribed |
      | 0       | 1     | 0      | 0             | 0           | 1            |


