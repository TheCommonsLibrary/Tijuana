class AlterEmailTargetTrackingLogs < ActiveRecord::Migration
  def up
    change_table :email_target_tracking_logs do |t|
      t.change :agent, :text
    end
  end

  def down
    change_table :email_target_tracking_logs do |t|
      t.change :agent, :string
    end
  end
end
