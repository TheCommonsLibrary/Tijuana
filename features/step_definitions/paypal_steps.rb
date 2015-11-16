Given /^I log into the PayPal sandbox$/ do
  raise 'No sandbox configured in config/paypal-sandbox.yml' unless defined?(PayPalSandbox)
  visit "https://www.sandbox.paypal.com/"
  account = PayPalSandbox["master"]["email"]
  password = PayPalSandbox["master"]["password"]
  unless page.driver.body.include? "Logged in as #{account.upcase}"
    step %Q{I follow "PayPal Sandbox"}
    step %Q{I fill in "Email Address" with "#{account}"}
    step %Q{I fill in "Password" with "#{password}"}
    step %Q{I check "Keep me logged in"}
    step %Q{I press "Log In"}
  end
end

When /^I log in to paypal as a member$/ do
  account = PayPalSandbox["master"]["email"]
  password = PayPalSandbox["master"]["password"]
  step %Q{I fill in "login_email" with "#{PayPalSandbox["member"]["email"]}"}
  step %Q{I fill in "login_password" with "#{PayPalSandbox["member"]["password"]}"}
  step %Q{I press "Log In"}
end
