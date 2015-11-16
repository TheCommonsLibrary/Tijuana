class AddMakeRecurringAtToDonations < ActiveRecord::Migration
  def change
    add_column :donations, :make_recurring_at, :timestamp
  end
end
