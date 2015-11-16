class AddCreatedAtToUae < ActiveRecord::Migration
  def change
    add_index :user_activity_events, [:created_at]
  end
end
