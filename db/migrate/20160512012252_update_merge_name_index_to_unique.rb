class UpdateMergeNameIndexToUnique < ActiveRecord::Migration
  def change
    remove_index :merges, :name => :index_merges_on_name
    add_index :merges, :name, :name => :index_merges_on_name, :unique => true
  end
end
