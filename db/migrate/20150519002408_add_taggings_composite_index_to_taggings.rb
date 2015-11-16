class AddTaggingsCompositeIndexToTaggings < ActiveRecord::Migration
  def change
    add_index "taggings", ["taggable_id", "taggable_type", "tag_id"], :name => "tags_list_cutter_idx"
  end
end
