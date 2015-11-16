class CreateNationbuilderSyncLogs < ActiveRecord::Migration
  def change
    create_table :nationbuilder_sync_logs do |t|
      t.string :source
      t.string :destination
      t.string :method
      t.string :endpoint
      t.text :data
      t.text :payload
      t.datetime :started_at
      t.datetime :completed_at
      t.integer :user_id
      t.timestamps
    end
    add_index :nationbuilder_sync_logs, :source
    add_index :nationbuilder_sync_logs, :user_id
    add_index :nationbuilder_sync_logs, :endpoint
  end
end
