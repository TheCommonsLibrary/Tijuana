@admin
Feature: Manage Donations
  In order to get money from donors
  As an administrator
  I want to change donations

Background:
  Given I run the seed task
  And I am logged in as an admin
  And I have a sample set of users

Scenario: View donations for a user
  Given user "getup1@getup.org.au" has a weekly recurring donation for "3000" dollars
  When I am on the edit admin user page for "getup1@getup.org.au"
  Then I should see "Recurring donations"
  And I should see "$3,000.00 weekly"

Scenario: Change donation amount frequency
  Given user "getup1@getup.org.au" has a weekly recurring donation for "394565" dollars
  When I am on the edit admin user page for "getup1@getup.org.au"
  And I follow "$394,565.00 weekly"
  When I select "Donate Monthly" from "Frequency"
  And I fill in "Amount" with "4997"
  And I fill in "Last four digits of Credit Card" with "4997"
  And I press "Save"
  Then I should be on the edit admin user page for "getup1@getup.org.au"
  And I should see "$4,997.00 monthly"
