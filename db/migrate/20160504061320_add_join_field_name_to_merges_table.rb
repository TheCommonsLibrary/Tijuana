class AddJoinFieldNameToMergesTable < ActiveRecord::Migration
  def change
    add_column :merges, :join_field_name, :string
  end
end
