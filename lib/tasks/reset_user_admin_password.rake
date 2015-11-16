require 'securerandom'
namespace :user_admin_password do
  desc 'Sets all admin passwords to a randomly generated hash'
  task :reset => :environment do
    User.where(is_admin: true).each do |user|
      PasswordMailer.deliver_all_admins_notification(user).deliver
    end

    User.privileged.update_all(encrypted_password: BCrypt::Password.create(SecureRandom.hex))
    User.privileged.each(&:send_reset_password_instructions)
  end
end
