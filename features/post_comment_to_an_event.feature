Feature: Event comments
  In order to more actively participate in GetUp! Events
  As a user
  I want to be able to post comments to an Event

Background: 
  Given I run the seed task
  And a user "Tom" "Mann" with email "tom.mann@example.com"
  And there is a "confirmed" upcoming Event "Tom's Event" for the Get Together "Save the Dolphins" hosted by "tom.mann@example.com"

Scenario: Event with no comments
  Given I am on the "Tom's Event" event page
  Then I should see "There are no comments."

Scenario: Posting a comment
  Given I am logged in as "tom.mann@example.com"
  And I am on the "Tom's Event" event page
  And I fill in "body" with "This is my first comment"
  And I press "Comment"
  Then I should be on the "Tom's Event" event page
  And I should see "This is my first comment"

Scenario: Replying to a comment
  Given I am logged in as "tom.mann@example.com"
  And there is a comment for the "Tom's Event" event posted by "tom.mann@example.com"
  And I am on the "Tom's Event" event page
  And I follow "Reply"
  And I fill in "body" with "This is a reply" within ".reply-to"
  And I press "Post Reply"
  Then I should be on the "Tom's Event" event page
  And I should see "This is a reply"

Scenario: I should not be able to comment if not logged in
  Given I am not logged in
  And I am on the "Tom's Event" event page
  Then I should not see the "comment" button
  
Scenario: I should be able to comment if logged in
  Given I am logged in as "tom.mann@example.com"
  And I am on the "Tom's Event" event page
  Then I should see the "comment" button