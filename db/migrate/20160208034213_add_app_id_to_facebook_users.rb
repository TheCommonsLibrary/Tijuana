class AddAppIdToFacebookUsers < ActiveRecord::Migration
  def change
    add_column :facebook_users, :app_id, :integer
    add_index :facebook_users, [:facebook_id, :user_id, :app_id]
  end
end
