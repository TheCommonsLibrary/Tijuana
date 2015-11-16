class DropSlugsTable < ActiveRecord::Migration
  def up
    drop_table :slugs
  end

  def down
    create_table "slugs" do |t|
      t.string "name"
      t.integer "sluggable_id"
      t.integer "sequence", default: 1, null: false
      t.string "sluggable_type", limit: 40
      t.string "scope"
      t.datetime "created_at"
    end
    add_index "slugs", ["name", "sluggable_type", "sequence", "scope"], name: "index_slugs_on_n_s_s_and_s", unique: true
    add_index "slugs", ["sluggable_id"], name: "index_slugs_on_sluggable_id"
  end
end
