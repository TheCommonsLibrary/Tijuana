class CreateCallOutcomes < ActiveRecord::Migration
  def change
    create_table :call_outcomes do |t|
      t.datetime :received_at
      t.datetime :call_date
      t.integer :user_id
      t.string :unique_call_id
      t.string :disposition
      t.string :campaign_type
      t.string :campaign_code
      t.string :campaign_name
      t.string :allocation_name
      t.string :dialed_number
      t.integer :dial_attempts
      t.integer :call_duration
      t.text :payload
    end
    add_index :call_outcomes, :user_id
  end
end
