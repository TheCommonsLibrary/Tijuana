@admin
Feature: Managing static pages
  In order to add content to the web site
  As a campaigner
  I want to create static pages with information about GetUp

Background:
  Given I run the seed task
  Given I am logged in as an admin
  And I am on the admin static pages page

Scenario: Adding a static page
  When I follow "About"
  Then I should be on the admin page sequence page for "About"
  And I should not see "Edit"
  When I follow "Add a page"
  And I fill in "Page Title" with "History"
  And I press "Create page"
  Then I should be on the content editing page for "History"
  When I follow "About" within "#admin-breadcrumbs"
  Then I should be on the admin page sequence page for "About"
  When I follow "Public" within "#pages li:last"
  Then I should be on the public static page "about/history"

@javascript
Scenario: Setting the Paginate option in a static page
  When I visit the admin "Landing Page for Static Page Sequence" page
  And I check "Paginate?" within "#main_content"
  And I press "Save page"
  Then I should see "'Landing Page for Static Page Sequence' has been updated"