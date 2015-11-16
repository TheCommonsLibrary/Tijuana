class CreateSources < ActiveRecord::Migration
  def change
    create_table :acquisition_sources do |t|
      t.string :source
      t.string :medium
      t.string :content
      t.string :name
      t.integer :user_id
      t.string :slug
      t.timestamps
    end
    add_index :acquisition_sources, :slug
    add_column :user_activity_events, :acquisition_source_id, :integer
    add_index :user_activity_events, :acquisition_source_id
  end
end
