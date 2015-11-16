Feature: Find Get Togethers
  In order to attend a Get Togeter event 
  As a user
  I want to find a Get Together

Background:
  Given I run the seed task
  And a user "Tom" "Mann" with email "tom.mann@example.com"

Scenario: View a list of upcoming Get Togethers
  Given there is an upcoming Get Together "Turnip and have fun"
  And there is a past Get Together "Lettuce party"
  When I am on the Get Togethers page
  And I should not see "Lettuce party" within ".upcoming-get-togethers"
  Then I should see "Turnip and have fun" within ".upcoming-get-togethers"
  

Scenario: View a list of archived Get Togethers
  Given there is an upcoming Get Together "Turnip and have fun"
  And there is a past Get Together "Lettuce party"
  When I am on the Get Togethers page
  Then I should not see "Turnip and have fun" within ".past-get-togethers"
  And I should see "Lettuce party" within ".past-get-togethers"

  

  
