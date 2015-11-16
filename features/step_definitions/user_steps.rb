Given /^a user "([^\"]*)" "([^\"]*)" with (.*)$/ do |first_name, last_name, details|
  user_params = {:first_name => first_name, :last_name => last_name}
  details.split(" and ").each do |field_and_value|
    match_data = /(.*) "(.*)"/.match(field_and_value)
    field, value = *match_data.captures
    user_params[field] = value
  end
  create(:user, user_params.merge(:password => "Password1"))
end

Given /^a "([^\"]*)" with email "(.*)"$/ do |role, email|
  attrs = {:email => email, :password => "Password1"}

  case role
  when /admin/ then 
    create :admin_user, attrs
  when /volunteer/ then
    create :volunteer_user, attrs
  else
    create :user, attrs
  end
end

Given /a user ([A-Z][a-z]+) ([A-Z][a-z]+) with email ([a-z]+@[a-z.]+)$/ do |first, last, email|
  create(:user, :first_name => first, :last_name => last, :email => email).save
end

Then /^the user "([^\"]*)" should be subscribed$/ do |email|
  u = User.find_by_email(email)
  u.should_not be_nil
  u.is_member.should be_truthy
end

Then /^the user "([^\"]*)" should be unsubscribed$/ do |email|
  u = User.find_by_email(email)
  u.should_not be_nil
  u.is_member.should be_falsey
end 

Given /^I am logged in as an admin$/ do
  visit new_user_session_path
  user = create(:admin_user, :email => "theadminuser@getup.org.au", :password => "Password1", :first_name => 'Admin', :last_name => 'User') unless User.find_by_email("theadminuser@getup.org.au")
  fill_in("Email", :with => user.email )
  fill_in("Password", :with => "Password1" )
  click_button("Sign in")
  page.has_css?("#code", :visible => true)
  fill_in('code', :with => user.otp_code)
  click_button('Sign in')
end

Then /^I fill in "([^\"]*)" with the member id of "([^\"]*)"$/ do |query_field, member_email|
  user = User.find_by_email member_email
  fill_in(query_field, :with => user.id)
end

Then /^I should see details for "([^\"]*)"$/ do |member_email|
  user = User.find_by_email member_email
  text = "ID: #{user.id}"
  if page.respond_to? :should
    page.should have_content(text)
  else
    assert page.has_content?(text)
  end
end

Given /^the following users exist:$/ do |table|
  table.hashes.each do |row|
    step %{a "#{row['Role']}" with email "#{row['Email']}"}
  end
end

Given /^I am logged in as "([^\"]*)"$/ do |email|
  visit new_user_session_path
  fill_in("Email", :with => email )
  fill_in("Password", :with => "Password1" )
  click_button("Sign in")

  user = User.find_by_email(email)
  if (user.is_admin || user.is_volunteer)
    page.has_css?("#code", :visible => true)
    fill_in('code', :with => user.otp_code)
    click_button('Sign in')
  end
end

Given /^I am not logged in/ do
  visit destroy_user_session_path
end


Given /^user "([^\"]*)" has a weekly recurring donation for "([^\"]*)" dollars$/ do |user_email, donation_amount|
  user = User.find_by_email(user_email)
  donation = create(:donation, :user => user)
  donation.amount_in_dollars = donation_amount
  donation.frequency = "weekly"
  donation.save
end
