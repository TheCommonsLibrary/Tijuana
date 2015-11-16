class AddMauticIdToContentModules < ActiveRecord::Migration
  def change
    add_column :content_modules, :mautic_id, :integer
  end
end
