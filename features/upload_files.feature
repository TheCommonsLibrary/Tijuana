@admin
Feature: Upload files
  In order to manage online content
  As a campaigner
  I want to be able to upload assets for users to download
    
  Background:
    Given I run the seed task
    Given I am logged in as an admin
  
  Scenario: Show no files
    Given I have 0 downloadable assets
    Then I am on the admin downloadable assets page
    Then I should see "No files have been uploaded yet."

  Scenario: Show one file
    Given I have 1 fixture downloadable assets
    Then I am on the admin downloadable assets page
    Then I should see "Last 1 file uploaded"

  Scenario: Show the limit (30) files
    Given I have 35 fixture downloadable assets
    Then I am on the admin downloadable assets page
    Then I should see "Last 30 files uploaded"

  Scenario: Upload a file
    Given I have 0 downloadable assets
    Then I am on the admin downloadable assets page
    And I upload a fixture downloadable asset
    And I press "Upload"
    Then I should see "Use the following HTML code to embed a download link in a page"