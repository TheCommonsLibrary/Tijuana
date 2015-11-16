class AddCacheKeyToMergesTable < ActiveRecord::Migration
  def change
    add_column :merges, :join_cache_key, :string
  end
end
