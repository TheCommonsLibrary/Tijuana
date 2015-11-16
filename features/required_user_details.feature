Feature: Required User Details management
  In order to collect user details
  As a campaigner
  I want to configure what details are requested

Background:
  Given I run the seed task
  Given a user "Stephen" "Frederickson" with email "sfrederickson@iheartfrancois.fr"

@javascript
Scenario: Required user details
  When I visit the "Landing Page for LGBT Petition" page
  And I fill in "user_email" with "sfrederickson@iheartfrancois.fr"
  Then I wait 1 seconds
  Then the "user_last_name" field should not contain "Frederickson"
  Then the "user_suburb" field should contain ""