Feature: Browsing through the website
  In order to have a better feedback from the app
  As a user
  I want to be informed that the current page requires javascript enabled to work correctly

Background:
  Given I run the seed task
  And a user "Tom" "Mann" with email "tom.mann@example.com"

Scenario: Visiting the Email your MP page
  Given I visit the "Landing Page for Walrus MP Email" page
  Then I should see /Please enable javascript on your browser to take full advantage of our website/

Scenario: Visiting a page that contains a donation module
  Given I visit the "Landing Page for Climate Donation" page
  Then I should see /Please enable javascript on your browser to take full advantage of our website/