class RenameTagsToOldTags < ActiveRecord::Migration
  def change
    rename_column :users, :tags, :old_tags
  end
end
