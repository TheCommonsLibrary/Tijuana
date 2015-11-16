Feature: Display subscription checkbox
  In order to receive regular updates
  As a user
  I want to subscribe to GetUp

Background:
  Given I run the seed task

@javascript @randomlyfailingwip
Scenario: New user taking action should see the subscribing box and subscribe
  When I visit the "Landing Page for Gunns Petition" page
  And I fill in email with "fred@example.com" and wait for lookup
  And I fill in "user_first_name" with "Fred"
  And I should see "Receive GetUp! updates"
  And the "user_is_member" checkbox should be checked
  And I press "SIGN THE PETITION!"
  Then the user "fred@example.com" should be subscribed

# @javascript
# Scenario: New user taking action should see the subscribing box and not subscribe
# When I visit the "Landing Page for Gunns Petition" page
# And I fill in "user_email_address" with "fred@example.com"
# And I fill in "user_first_name" with "Fred"
# And I should see "Receive GetUp! updates"
# And I uncheck  "user_is_member"
# And I press "SIGN THE PETITION!"
# Then the user "fred@example.com" should not be subscribed
# 
# 
# Scenario: Existing user who is unsubscribed taking an action should see the subscribing box and resubscribe
# 
# 
# Scenario: Existing user who is unsubscribed taking an action should see the subscribing box and not resubscribe
