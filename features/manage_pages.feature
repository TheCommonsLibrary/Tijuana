@admin
Feature: Managing pages and page sequence
  In order to add content to the web site
  As a campaigner
  I want to create page sequence for campaigns

Background:
  Given I run the seed task
  Given I am logged in as an admin

Scenario: View list of page sequence
  When I visit the "Forestry" campaign page
  Then I should see "Forestry"
  And I should see "Gunns Petition"
  And I should see "Landing Page for Gunns Petition"
  And I should see "Thankyou Page for Gunns Petition"

Scenario: Add a page sequence
  When I visit the "Forestry" campaign page
  And I follow "Add a page sequence"
  Then I should see "Name is used for the URL and will be visible to the public."
  And I fill in "Name" with "Pulp Mill Woes"
  And I fill in "Facebook Image URL" with "http://fb.png"
  And I press "Create page sequence"
  Then I should be on the admin page sequence page for "Pulp Mill Woes"
  And I should see "Pulp Mill Woes"

Scenario: Add pages to a sequence
  When I visit the "Gunns Petition" page sequence page
  And I follow "Add a page"
  Then I should see "Page title will be displayed to the public and will be used in the URL."
  And I fill in "Page Title" with "Petition page for Gunns"
  And I press "Create page"
  Then I should be on the content editing page for "Petition page for Gunns"
  And I should see "Created less than a minute ago by Admin User"
  And I should see "Updated less than a minute ago by Admin User"

Scenario: Set the theme for a page sequence
  When I visit the "Gunns Petition" page sequence page
  And I follow "Edit sequence"
  And I select "Sad" from "Theme"
  And I press "Save"
  And I follow "Edit sequence"
  Then "Sad" should be selected for "Theme"

Scenario: Duplicate a page sequence
  When I visit the "Forestry" campaign page
  And I follow "Duplicate" for "Gunns Petition" page sequence
  Then I should see "Gunns Petition(1)"
  Then I should be on the admin campaign page for "Forestry"
  Then I follow "Manage Pages" for "Gunns Petition(1)" page sequence
  Then I should be on the admin page sequence page for "Gunns Petition(1)"
  Then I should see "Landing Page for Gunns Petition"
  And I should see "Thankyou Page for Gunns Petition"
  
Scenario: Duplicate of a duplicate
  When I visit the "Forestry" campaign page
  And I follow "Duplicate" for "Gunns Petition" page sequence
  Then I should see "Gunns Petition(1)"
  And I follow "Duplicate" for "Gunns Petition(1)" page sequence 
  Then I should see "Gunns Petition(1)(1)"
  
Scenario: Duplicating a page when an unrenamed duplicate exists
  When I visit the "Forestry" campaign page
  And I follow "Duplicate" for "Gunns Petition" page sequence
  Then I should see "Gunns Petition(1)"
  And I follow "Duplicate" for "Gunns Petition" page sequence 
  Then I should see "Gunns Petition(2)"
  
@javascript
Scenario: Deleting a Page sequence
  When I visit the "Forestry" campaign page
  And I follow "Gunns Petition"
  And I click "Cancel" after following "Delete sequence" 
  Then I should not see "'Gunns Petition' has been deleted"
  When I click "OK" after following "Delete sequence"
  Then I should see "'Gunns Petition' has been deleted"
  And I should not see "Gunns Petition" within "#page-sequences-list"
  
@javascript
Scenario: Deleting a Page
  When I visit the "Forestry" campaign page
  And I follow "Gunns Petition"
  When I follow "Landing Page for Gunns Petition"
  And I click "Cancel" after following "Delete page"
  Then I should not see "'Landing Page for Gunns Petition' has been deleted"
  When I click "OK" after following "Delete page"
  Then I should see "'Landing Page for Gunns Petition' has been deleted"  
  And I should not see "Landing Page for Gunns Petition" within "#pages"