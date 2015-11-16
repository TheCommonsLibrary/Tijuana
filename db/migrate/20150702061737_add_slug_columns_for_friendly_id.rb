class AddSlugColumnsForFriendlyId < ActiveRecord::Migration
  def up
    tables = %i(campaigns events get_togethers pages page_sequences)

    tables.each do |table|
      add_column table, :slug, :string
      execute "UPDATE #{table} t SET t.slug = ( SELECT f.slug FROM friendly_id_slugs f WHERE f.sluggable_type = '#{table.to_s.classify}' AND sluggable_id = t.id ORDER BY f.id DESC LIMIT 1 )"
      add_index table, :slug
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
