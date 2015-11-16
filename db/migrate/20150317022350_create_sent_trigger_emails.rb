class CreateSentTriggerEmails < ActiveRecord::Migration
  def change
    create_table :sent_trigger_emails do |t|
      t.string :key
      t.datetime :sent_date
      t.integer :user_id
    end
    add_index :sent_trigger_emails, [:user_id, :sent_date, :key]
  end
end
