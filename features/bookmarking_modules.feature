@admin @javascript
Feature: Bookmarking modules
  In order to avoid duplicated effort
  As a campaigner
  I want to bookmark modules and reuse them between pages

Background:
  Given I run the seed task
  Given I am logged in as an admin
  And I visit the admin "Landing Page for Gunns Petition" page
  And I follow "Bookmark" for the HTML module "Save the kittens!"
  And I fill in "bookmark_name" with "Reusable Kittens"
  And I press "Add Bookmark"
  
@javascript
Scenario: Reusing a bookmark
  When I visit the admin "Landing Page for Blank Slate" page
  And I follow "Bookmarks" inside the container "MAIN CONTENT"
  When I wait until I can see ".add-from-bookmark"
  And I follow "Reusable Kittens"
  Then I should see "Save the kittens!" inside the container "MAIN CONTENT"
  And I should see "This module is linked to multiple pages"
  And the "Content" field should be disabled
  And the field with "Save the kittens!" should be disabled

@javascript
Scenario: Unbookmarking
  When I follow "Unbookmark" inside the container "MAIN CONTENT"
  And I press "Yes"
  And I visit the admin "Landing Page for Blank Slate" page
  And I follow "Bookmarks" inside the container "MAIN CONTENT"
  And I wait until I can see ".add-from-bookmark"
  Then I should not see "Reusable Kittens"

@javascript
Scenario: Editing a bookmarked module linked to multiple pages
  When I visit the admin "Landing Page for Blank Slate" page
  And I follow "Bookmarks" inside the container "MAIN CONTENT"
  When I wait until I can see ".add-from-bookmark"
  And I follow "Reusable Kittens"
  And I wait 0.5 seconds
  And I follow "Unlock editing"
  Then the "Content" field should not be disabled
  When I replace "Save the kittens!" with "Destroy the kittens!"
  And I press "Save page"
  And I visit the admin "Landing Page for Gunns Petition" page
  Then I should not see "Save the kittens!"
  And I should see "Destroy the kittens!"

@javascript
Scenario: Unlinking a bookmarked module linked to multiple pages
  When I visit the admin "Landing Page for Blank Slate" page
  And I follow "Bookmarks" inside the container "MAIN CONTENT"
  When I wait until I can see ".add-from-bookmark"
  And I follow "Reusable Kittens"
  And I wait 0.5 seconds
  And I click "OK" after following "Unlink this module"
  Then I should not see "This module is linked to multiple pages"
  When I replace "Save the kittens!" with "Save the capybara!"
  And I press "Save page"
  And I visit the admin "Landing Page for Gunns Petition" page
  Then I should not see "Save the capybara!"
  And I should see "Save the kittens!"

@javascript
Scenario: Unbookmarking and leaving reused modules linked
  When I visit the admin "Landing Page for Blank Slate" page
  And I follow "Bookmarks" inside the container "MAIN CONTENT"
  When I wait until I can see ".add-from-bookmark"
  And I follow "Reusable Kittens"
  Then I should see "Unbookmark"
  When I click "OK" after following "Unbookmark"
  Then I should see "This module is linked to multiple pages"
