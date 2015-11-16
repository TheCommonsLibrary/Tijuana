class AddIndexesToUserEmails < ActiveRecord::Migration
  def change
    add_index :user_emails, :created_at
    add_index :email_target_tracking_logs, :user_email_id
  end
end
