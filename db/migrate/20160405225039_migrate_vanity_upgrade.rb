class MigrateVanityUpgrade < ActiveRecord::Migration
  def change
    add_column :vanity_experiments, :enabled, :boolean
  end
end
