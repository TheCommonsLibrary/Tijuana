class AddDoNotCall < ActiveRecord::Migration
  def change
    add_column :users, :do_not_call, :boolean, default: false
    add_index :users, :do_not_call
  end
end
