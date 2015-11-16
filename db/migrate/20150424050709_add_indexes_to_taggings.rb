class AddIndexesToTaggings < ActiveRecord::Migration
  def change
    add_index :taggings, [:taggable_type, :taggable_id, :context]
  end
end
