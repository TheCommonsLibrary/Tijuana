class ModifyIndexOnTaggings < ActiveRecord::Migration
  def change
    remove_index :taggings, :name => :taggings_idx
    remove_index :taggings, :name => :index_taggings_on_taggable_type_and_taggable_id_and_context
    add_index "taggings", ["tag_id", "taggable_id", "taggable_type", "context"], :name => "taggind_idx", :unique => true
  end
end
