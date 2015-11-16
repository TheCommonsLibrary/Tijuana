class CreateIssues < ActiveRecord::Migration
  def up
    create_table :issues do |t|
      t.integer :electorate_id
      t.string :state
      t.string :seat
      t.string :issue
      t.string :title
      t.string :blurb_heading
      t.string :blurb_content
      t.string :strap
      t.string :party_order
      t.string :alp_blurb
      t.string :grn_blurb
      t.string :awi_blurb
      t.string :smi_blurb
      t.string :nxt_blurb
      t.string :roi_blurb
      t.text :data
      t.timestamps
    end
    add_index :issues, :seat
  end

  def down
    drop_table :issues
  end
end
