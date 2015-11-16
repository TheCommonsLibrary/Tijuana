class CreateNationBuilderUsers < ActiveRecord::Migration
  def change
    create_table :nation_builder_users do |t|
      t.string :nationbuilder_site
      t.integer :nationbuilder_id
      t.integer :user_id

      t.timestamps
    end
    add_index :nation_builder_users, :nationbuilder_id
    add_index :nation_builder_users, [:nationbuilder_id, :nationbuilder_site], name: 'site_and_id_idx'
  end
end
