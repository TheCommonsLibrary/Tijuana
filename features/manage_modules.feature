@admin
Feature: Managing modules
  In order to add content to the web site
  As a campaigner
  I want to manage modules for a page

Background:
  Given I run the seed task
  Given I am logged in as an admin
  And I visit the admin "Landing Page for Blank Slate" page

@javascript
Scenario: Adding an HTML module to the main content
  When I follow "Add HTML" inside the container "MAIN CONTENT"
  Then I should see "Html Module"
  When I fill in the textarea with "Trees are ace" inside the container "MAIN CONTENT"
  And I press "Save page"
  Then I should see "'Landing Page for Blank Slate' has been updated."
  When I visit the admin "Landing Page for Blank Slate" page
  Then I should see "Trees are ace" inside the container "MAIN CONTENT"

@javascript
Scenario: Adding an HTML module to the header section
  When I follow "Add HTML" inside the container "HEADER CONTENT"
  Then I should see "Html Module"
  When I fill in the textarea with "This goes in the header" inside the container "HEADER CONTENT"
  And I press "Save page"
  Then I should see "'Landing Page for Blank Slate' has been updated."
  When I visit the admin "Landing Page for Blank Slate" page
  Then I should see "This goes in the header" inside the container "HEADER CONTENT"

@javascript
Scenario: Removing an HTML Module
  When I follow "Add HTML" inside the container "HEADER CONTENT"
  Then I should see "Html Module"
  When I fill in the textarea with "Down with this sort of thing!" inside the container "HEADER CONTENT"
  And I press "Save page"
  When I visit the admin "Landing Page for Blank Slate" page
  And I follow "Remove module" for the module "Down with this sort of thing!" and click "Cancel"
  Then I should see "Down with this sort of thing!"
  When I follow "Remove module" for the module "Down with this sort of thing!" and click "OK"
  Then I should not see "Html Module"
  Then I should not see "Down with this sort of thing!"

@javascript
Scenario: Moving a module between containers
  When I follow "Add HTML" inside the container "MAIN CONTENT"
  Then I should see "Html Module"
  When I fill in the textarea with "Careful now." inside the container "MAIN CONTENT"
  And I press "Save page"
  When I visit the admin "Landing Page for Blank Slate" page
  Then I should see "Careful now." inside the container "MAIN CONTENT"
  When I follow "Move to sidebar" for the HTML module "Careful now."
  Then I should see "Careful now." inside the container "SIDEBAR"
  Then I visit the admin "Landing Page for Blank Slate" page
  Then I should see "Careful now." inside the container "SIDEBAR"

@javascript
@wip
Scenario: Moving module between containers and saving
  When I follow "Add accordion" within the container "SIDEBAR"
  Then I follow "Add HTML" within the container "MAIN CONTENT"
  Then I fill in "Title" with "Test Title"
  When I fill in "Content" with "Careful now."
  And I press "Save page"
  When I visit the admin "Landing Page for Blank Slate" page
  When I follow "Move to main content" for the Accordion module "Careful now."
  Then I should see "Careful now." within the container "SIDEBAR"
  And I press "Save page"
  Then I visit the admin "Landing Page for Blank Slate" page

@javascript
Scenario: Adding an Direct Landing HTML module to the main content
  When I follow "Add Direct Landing HTML" inside the container "MAIN CONTENT"
  Then I should see "Direct Landing Html Module"
  When I fill in the textarea with "GetUp information" inside the container "MAIN CONTENT"
  And I press "Save page"
  Then I should see "'Landing Page for Blank Slate' has been updated."
  When I visit the admin "Landing Page for Blank Slate" page
  Then I should see a textarea with "GetUp information"

@javascript
Scenario: Adding a petition
  When I follow "Add a petition"
  And I choose "Voice (e.g. petition)"
  And I fill in "Title" with "petition contre Sarkozy"
  And I fill in "Petition statement" with "Monsieur le President blablablabla ..."
  And I fill in "Target number" with "100"
  And I fill in "Show progress at" with "50"
  And I fill in "Button text" with "Virez le!"
  And I press "Save page"
  Then I should see "'Landing Page for Blank Slate' has been updated."
  When I visit the admin "Landing Page for Blank Slate" page
  Then the "Title" field should contain "petition contre Sarkozy"
  And the "Petition statement" field should contain "Monsieur le President blablablabla ..."
  And the "Target number" field should contain "100"
  And the "Show progress at" field should contain "50"
  And the "Button text" field should contain "Virez le!"

@javascript
Scenario: Server validation failures
  When I follow "Add a petition"
  Then I should see "Petition Module"
  # skip client validation
  And I choose "Voice (e.g. petition)"
  And I press "Save page"
  Then I should not see "'Landing Page for Blank Slate' has been updated."
  And I should see "Title is too short (minimum is 3 characters)"

@javascript
Scenario: Adding an Email MP module (contains only federal as jurisdiction) to the main content
  When I follow "Add an email to MP" inside the container "SIDEBAR"
  Then I should see "Email Mp Module"
  Then I should see "Federal" as a jurisdiction
  Then I should see "Australian Labor Party,Liberal Party,Australian Greens,National Party,Country Liberal Party,Family First Party,Independents,Democratic Labor Party" as a party option
  Then I should see "MPs" as the selected target option
  And I fill in "Title" with "Email Them"
  And I fill in "Default subject" with "Spam! Spam!"
  And I fill in "Default body" with "This is a mail to let you about all my worldly problems"
  And I select "Federal" from "jurisdiction-select"
  And I check "Liberal Party"
  And I press "Save page"
  Then I should see "'Landing Page for Blank Slate' has been updated."
  And I visit the admin "Landing Page for Blank Slate" page
  Then I should see "Federal" as a jurisdiction
  Then the "Liberal Party" checkbox should be checked
  Then I should see "MPs" as the selected target option
