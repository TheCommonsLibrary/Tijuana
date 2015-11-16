class CreatePrePollingBooths < ActiveRecord::Migration
  def change
    create_table :pre_polling_booths do |t|
      t.string :premises_name
      t.string :address
      t.string :suburb
      t.integer :postcode_id
      t.string :booth_location
      t.string :booth_gate
      t.string :booth_entrance
      t.string :wheelchair
      t.text :hours
      t.decimal :longitude, precision: 15, scale: 12
      t.decimal :latitude, precision: 15, scale: 12
      t.timestamps
    end

    create_table :electorates_pre_polling_booths, id: false do |t|
      t.integer :electorate_id, null: false
      t.integer :pre_polling_booth_id, null: false
    end
  end
end
