class AddNullFalseToTimestampFields < ActiveRecord::Migration
  def up
    change_column :campaigns, :created_at, :datetime, null: false
    change_column :campaigns, :updated_at, :datetime, null: false

    ContentModule.where('updated_at IS NULL').each{|r| r.update_column('updated_at', '2008-01-01') }
    change_column :content_modules, :created_at, :datetime, null: false
    change_column :content_modules, :updated_at, :datetime, null: false

    change_column :events, :created_at, :datetime, null: false
    change_column :events, :updated_at, :datetime, null: false

    change_column :get_togethers, :created_at, :datetime, null: false
    change_column :get_togethers, :updated_at, :datetime, null: false

    change_column :pushes, :created_at, :datetime, null: false
    change_column :pushes, :updated_at, :datetime, null: false

    change_column :themes, :created_at, :datetime, null: false
    change_column :themes, :updated_at, :datetime, null: false
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
