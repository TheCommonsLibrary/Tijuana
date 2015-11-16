class AddDynamicAttributesToUserEmails < ActiveRecord::Migration
  def change
    add_column :user_emails, :dynamic_attributes, :text
  end
end
