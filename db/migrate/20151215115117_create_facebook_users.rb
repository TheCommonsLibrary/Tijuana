class CreateFacebookUsers < ActiveRecord::Migration
  def change
    create_table :facebook_users do |t|
      t.integer :user_id
      t.string :facebook_id

      t.timestamps
    end
    add_index :facebook_users, [:user_id, :facebook_id]
    add_index :facebook_users, :user_id
  end
end
