class ChangesForFriendlyIdUpgrade < ActiveRecord::Migration
  def up
    execute "CREATE TABLE friendly_id_slugs LIKE slugs"
    execute "INSERT friendly_id_slugs SELECT * FROM slugs"

    # ensure sequences (duplicates) are maintained
    execute "UPDATE friendly_id_slugs SET `name` = concat(`name`,'--',sequence) WHERE sequence > 1"
    remove_index :friendly_id_slugs, name: :index_slugs_on_n_s_s_and_s
    remove_column :friendly_id_slugs, :sequence

    rename_column :friendly_id_slugs, :name, :slug
    change_column_null :friendly_id_slugs, :slug, false

    change_column :friendly_id_slugs, :sluggable_type, :string, limit: 50

    execute "DELETE FROM friendly_id_slugs WHERE sluggable_id IS NULL"
    change_column_null :friendly_id_slugs, :sluggable_id, false

    change_column_null :friendly_id_slugs, :created_at, false

    add_index :friendly_id_slugs, [:slug, :sluggable_type]
    add_index :friendly_id_slugs, :sluggable_type
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
