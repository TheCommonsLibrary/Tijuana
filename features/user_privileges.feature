Feature: Ensure users have the correct access to parts of the application

Background:
 Given I run the seed task
 And the following users exist:
    | Email                     | Role      |
    | andrew@getup.org.au       | admin     |
    | veronica@getup.org.au     | volunteer |
    | mike@example.com          | member    |
    | eviluser@evil.example.com |           |

  Scenario Outline: admin and volunteer have access to admin section
    Given I am logged in as "<Email>"
    When I go to the home page
    Then I should see <User Info> within ".usernavbg"
    When I go to the page with URL "/admin"
    Then I should be on the page with URL <Destination>
    And I should see <login-nav menu> within ".login-nav"

  Examples:
    | Email                     | User Info | Destination | login-nav menu            |
    | andrew@getup.org.au       | "Admin"   | "/admin"    | "Admin"                   |
    | veronica@getup.org.au     | "Admin"   | "/admin"    | "Admin"                   |


  @javascript @focus
  Scenario Outline: member and others do not have access to admin section
  Given I am logged in as "<Email>"
  When I go to the home page
  Then I should see <User Info> within ".usernavbg"
  When I go to the page with URL "/admin"
  Then I should be on the page with URL <Destination>
  And I should see <Flash Message>

  Examples:
    | Email                     | User Info | Destination | Flash Message                                  |
    | mike@example.com          | "LOG OUT" | "/"         | "Only administrators can view the admin pages" |
    | eviluser@evil.example.com | "LOG OUT" | "/"         | "Only administrators can view the admin pages" |

@wip
Scenario: Users are able to manage their own events
  Given I am logged in as "mike@example.com"
  And there is an event "Bondi sword swallowing party" for the "Eat swords" Get Together
  When I visit "Bondi sword swallowing party"
  Then I should see "Edit"
