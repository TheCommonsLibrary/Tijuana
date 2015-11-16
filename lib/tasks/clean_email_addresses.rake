namespace :clean do
  desc 'Remove new line from end of User email addresses'
  task :user_email_addresses => :environment do
    new_line = "\n"
    users = User.where('email LIKE :email', {:email => "%#{new_line}"})
    users.each do |user|
      user.email.gsub(new_line, '')
      save_email(user)
    end
  end

  def save_email(user)
    begin
      user.save!
      puts "#{user.email} updated"
    rescue
      puts "#{user.email} not updated, email already exists"
    end
  end
end