class AddHiddenFromAdmin < ActiveRecord::Migration
  def change
    add_column :campaigns, :hidden_in_admin, :boolean, default: false
  end
end
