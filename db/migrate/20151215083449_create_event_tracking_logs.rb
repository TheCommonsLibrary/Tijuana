class CreateEventTrackingLogs < ActiveRecord::Migration
  def change
    create_table :event_tracking_logs do |t|
      t.integer :user_id
      t.string :name
      t.string :context
      t.text :agent
      t.text :referrer
      t.string :ip
      t.timestamps
    end
    add_index :event_tracking_logs, :user_id
  end
end
