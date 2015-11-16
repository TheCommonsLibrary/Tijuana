@admin
Feature: Managing campaigns
  In order to manage campaigns
  As a campaigner
  I want to be able to find, create, edit and delete them through the backend
  
  Background:
    Given I run the seed task
    Given I am logged in as an admin
    Given I have a campaign named "Narwhal conservation"
    And I am on the admin campaigns page
    
  @javascript
  Scenario: Searching for a Campaign
    When I fill in "query" with "Ducky"
    And I press "Search"
    Then I should be on the admin campaigns page
    And I should not see "Narwhal conservation"
    And I should not see "Ducky"    
    When I fill in "query" with "Narwhal"
    And I press "Search"
    Then I should be on the admin campaigns page
    And I should see "Narwhal conservation"

  @javascript
    Scenario: Creating a Campaign
    When I follow "Create new campaign"
    Then I should see "Name is used for the URL and will be visible to the public. Description is for internal use only."
    And I fill in "Name" with "Save the kittens!"
    And I fill in "Description" with "Won't somebody think of the kittens?"
    And I select "Core" from "Pillar"
    And I press "Create campaign"
    Then I should see "'Save the kittens!' has been saved."
    And I should be on the admin campaign page for "Save the kittens!"

  @javascript
  Scenario: Deleting an existing campaign
    When I follow "Narwhal conservation"
    And I click "Cancel" after following "Delete campaign"
    And I should not see "'Narwhal conservation' has been deleted"
    And I should be on the admin campaign page for "Narwhal conservation"
    When I click "OK" after following "Delete campaign"
    Then I should be on the admin campaigns page
    And I should see "'Narwhal conservation' has been deleted"
    And I should not see "Narwhal conservation" within "#campaigns-list"


