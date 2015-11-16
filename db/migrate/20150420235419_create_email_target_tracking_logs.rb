class CreateEmailTargetTrackingLogs < ActiveRecord::Migration
  def change
    create_table :email_target_tracking_logs do |t|
      t.integer :user_email_id
      t.string :agent
      t.string :referrer
      t.string :ip
      t.string :cookie

      t.timestamps
    end
  end
end
