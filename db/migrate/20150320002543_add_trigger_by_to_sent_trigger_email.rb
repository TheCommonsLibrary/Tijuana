class AddTriggerByToSentTriggerEmail < ActiveRecord::Migration
  def up
    change_table :sent_trigger_emails do |t|
      t.references :triggered_by, :polymorphic => true
    end
  end

  def down
    change_table :sent_trigger_emails do |t|
      t.remove_references :triggered_by, :polymorphic => true
    end
  end
end
