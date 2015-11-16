class AddUserActivityEventToQuarantines < ActiveRecord::Migration
  def change
    add_column :quarantines, :user_activity_event_id, :integer
  end
end
