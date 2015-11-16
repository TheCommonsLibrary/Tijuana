class UpgradeTextFieldsToHandleHtmlEmails < ActiveRecord::Migration
  def change
    change_column :emails, :body, :mediumtext
    change_column :emails, :sent_to_users_ids, :mediumtext
    change_column :delayed_jobs, :handler, :mediumtext
    change_column :delayed_jobs, :last_error, :mediumtext
  end
end
