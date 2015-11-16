class CreateCandidates < ActiveRecord::Migration
  def up
    create_table :candidates do |t|
      t.integer :electorate_id
      t.string :seat
      t.string :state
      t.string :first_name
      t.string :last_name
      t.string :party_name
      t.integer :ballot_order
      t.integer :alp
      t.integer :grn
      t.integer :nxt
      t.integer :roi
      t.integer :awi
      t.integer :smi
      t.integer :ref
      t.text :data
      t.timestamps
    end
    add_index :candidates, :seat
  end

  def down
    drop_table :candidates
  end
end
