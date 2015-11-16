module LookupHelper
  def user_lookup_complete
    execute_script "$.fx.off = true;" # disable animations, coz poltergeist is too fast
    wait_until { page.find('.user-lookup-message').visible? }
  end
  
  def fill_in_email(email)
    fill_in 'Email Address', :with => email
    user_lookup_complete
  end
end

RSpec.configuration.include LookupHelper, :type => :feature
