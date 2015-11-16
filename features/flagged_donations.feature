Feature: Flagged donations
In order reduce the defaults on getup donations
As an administrator
I want to see all donations that require attention

Background:
  Given I run the seed task
  And I am logged in as an admin
  And a user "Tom" "Mann" with email "tom.mann@example.com"
  And "tom.mann@example.com" has an active flagged donation

@javascript
Scenario: Administrator sees the list of flagged donations
  When I go to the page with URL "/admin/donations/flagged"
  Then I should see the following flagged donations:
    | user                            | amount | reason                |
    | Tom Mann (tom.mann@example.com) | $30.00 | Expiring Credit Card  |
    | Tom Mann (tom.mann@example.com) | $30.00 | Expiring Credit Card  |

