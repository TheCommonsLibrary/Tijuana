class AddSecureLinksToEmails < ActiveRecord::Migration
  def change
    add_column :emails, :secure_links, :boolean, default: false
  end
end
