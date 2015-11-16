Feature: Ensure users have the correct access to parts of the application

Background:
 Given I run the seed task
 And the following users exist:
    | Email                     | Role      |
    | andrew@getup.org.au       | admin     |
    | veronica@getup.org.au     | volunteer |
    | mike@example.com          | member    |
    | eviluser@evil.example.com |           |

@wip
Scenario: User is returned to origin page after login
  Given I am logged in as "mike@example.com"
  When I go to "some page"
  And it redirects me to the login page
  When I login
  Then I am on "some page"
