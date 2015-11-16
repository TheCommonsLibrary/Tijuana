class AddPageIdToSources < ActiveRecord::Migration
  def change
    add_column :acquisition_sources, :page_id, :integer, index: true
  end
end
