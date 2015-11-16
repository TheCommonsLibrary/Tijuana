class AddSendToTargetToUserEmail < ActiveRecord::Migration
  def change
    add_column :user_emails, :send_to_target, :boolean, :default => true
  end
end
