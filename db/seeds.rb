require 'rake'

unless Rails.env.production?
  Rake::Task['import:home_page'].invoke
  Rake::Task['import:electoral:data'].invoke
  Rake::Task['import:themes'].invoke
  MemberCountCalculator.init
  Stats::TransparencyStats.new.update

  # Create the Umbrella User.
  # It's used for offline donations when a user (1) doesn't exist in our database AND (2) doesn't have an email address
  User.create_with(first_name: 'Umbrella', last_name: 'User').find_or_create_by(email: 'offlinedonations@getup.org.au')
  User.create_with(is_admin: true, is_member: true).find_or_create_by(email: 'info+shared_connection@getup.org.au')

  email = 'admin@admin.com'
  pass = 'password'
  puts "Creating dev admin user #{email} / #{pass}"
  User.create_with(first_name: 'admin', last_name: 'admin', password: pass, is_admin: true).find_or_create_by(email: email)
end
