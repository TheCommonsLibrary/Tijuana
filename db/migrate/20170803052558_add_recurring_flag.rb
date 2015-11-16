class AddRecurringFlag < ActiveRecord::Migration
  def change
    add_column :transactions, :recurring_flag, :boolean, default: false
  end
end
