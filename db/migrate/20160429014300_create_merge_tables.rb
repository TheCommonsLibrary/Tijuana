class CreateMergeTables < ActiveRecord::Migration
  def change
    create_table :merges do |t|
      t.string :name
      t.string :join_key
      t.string :description
      t.timestamps
    end
    add_index :merges, :name

    create_table :merge_records do |t|
      t.integer :join_id
      t.string :name
      t.string :value
      t.integer :merge_id
      t.timestamps
    end
    add_index :merge_records, [:merge_id, :name]
  end
end
