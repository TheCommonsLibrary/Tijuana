@admin
Feature: Upload images
  In order to manage online content
  As a campaigner
  I want to be able to upload and resize images

  Background:
    Given I run the seed task
    Given I am logged in as an admin

  @javascript
  Scenario: Show and hide elements
    Given I am on the admin images page
    When I follow "Upload a new image"
    And I check "Resize image"
    Then I should see "Preset dimensions"
    
  Scenario: Show no images
    Given I have 0 fixture images
    And I am on the admin images page
    Then I should see "No images have been uploaded yet."

  Scenario: Show one image
    Given I have 1 fixture image
    And I am on the admin images page
    Then I should see "Last 1 image uploaded"

  Scenario: Show the limit (30) images
    Given I have 35 fixture images
    And I am on the admin images page
    Then I should see "Last 30 images uploaded"

  Scenario: Upload an image
    Given I have 0 images
    And I am on the admin images page
    When I follow "Upload a new image"
    And I upload a fixture image file
    And I press "Upload"
    Then I should see "Image Preview"