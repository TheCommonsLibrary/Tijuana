class SetLimitOnAppIdColumnInFacebookUsers < ActiveRecord::Migration
  def change
    change_column :facebook_users, :app_id, :integer, limit: 8
  end
end
