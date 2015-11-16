class UpgradeTextFieldsToHandleHtmlEmails2 < ActiveRecord::Migration
  def change
    change_column :sent_emails, :body, :mediumtext
  end
end
