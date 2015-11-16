namespace :member do
  desc "'delete' a user by email. eg. rake member:delete[member@example.com]"
  task :delete, [:email] => [:environment] do |t, args|
    if (user = User.find_by_email(args[:email]))
      user.delete
      puts "#{user.email} deleted"
    else
      puts "User with email '#{args[:email]}' not found (or already deleted)"
    end
  end
end
