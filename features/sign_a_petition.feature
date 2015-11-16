Feature: Signing a petition
  In order to show my support
  As a user
  I want to add my signature to a petition

Background:
  Given I run the seed task

@javascript
Scenario: Signing a petition as an existing user with javascript
  Given a user "Fred" "Smith" with email "fred@example.com"
  When I visit the "Landing Page for Gunns Petition" page
  And I fill in email with "fred@example.com" and wait for lookup
  And I press "Sign the petition!"
  Then I should see "Thankyou Page for Gunns Petition"
  
Scenario: Signing a petition as an existing user without javascript
  Given a user "Fred" "Smith" with email "fred@example.com"
  When I visit the "Landing Page for Gunns Petition" page
  And I fill in "user_email" with "fred@example.com"
  And I fill in "user_first_name" with "Fred"
  And I press "Sign the petition!"
  Then I should see "Thankyou Page for Gunns Petition"  
  
Scenario: Signing a petition with an invalid email address
  When I visit the "Landing Page for Gunns Petition" page
  And I fill in "user_email" with "not an address"
  And I press "Sign the petition!"
  Then I should see "Landing Page for Gunns Petition"
  And I should see "Email is invalid"
  
Scenario: Signing a petition as a new user
  When I visit the "Landing Page for Gunns Petition" page
  And I fill in "user_email" with "someone.new@email.com"
  And I press "Sign the petition!"
  Then I should see "Landing Page for Gunns Petition"
  And I should see "First name can't be blank"
  When I fill in "user_first_name" with "Ozymandias"
  And I press "Sign the petition!"
  Then I should see "Thankyou Page for Gunns Petition"
