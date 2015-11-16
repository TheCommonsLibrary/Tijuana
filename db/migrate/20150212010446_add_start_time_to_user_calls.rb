class AddStartTimeToUserCalls < ActiveRecord::Migration
  def change
    add_column :user_calls, :start_time, :datetime
  end
end
