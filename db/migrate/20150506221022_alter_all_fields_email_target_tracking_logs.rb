class AlterAllFieldsEmailTargetTrackingLogs < ActiveRecord::Migration
  def up
    change_table :email_target_tracking_logs do |t|
      t.change :referrer, :text
    end
  end

  def down
    change_table :email_target_tracking_logs do |t|
      t.change :referrer, :string
    end
  end
end
