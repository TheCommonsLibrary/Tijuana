ActionMailer::Base.smtp_settings = {
  :address => 'smtp.sendgrid.com',
  :domain => ENV['HOST'],
  :port => 25,
  :user_name => ENV['SENDGRID_USER'],
  :password => ENV['SENDGRID_PASS'],
  :authentication => :plain,
  :enable_starttls_auto => false
}
