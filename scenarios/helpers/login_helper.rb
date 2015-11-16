module LoginHelper
  def sign_in(opts = {})
    opts = { :email => 'mygetup@getup.org.au', :password => 'password' }.merge opts
    visit new_user_session_path
    fill_in 'Email', with: opts[:email]
    fill_in 'Password', with: opts[:password]
    click_button 'Sign in'
  end

  def sign_in_as_admin(opts = {})
    opts = { :email => 'mygetup@getup.org.au', :password => 'password' }.merge opts
    sign_in opts
    find 'label', :text => 'Secure code'
    secure_code = User.find_by_email(opts[:email]).otp_code
    fill_in 'Secure code', :with => secure_code
    click_button 'Sign in'
  end
end

RSpec.configuration.include LoginHelper, :type => :feature
