class AddExtraFieldsToElectoratesPostcodes < ActiveRecord::Migration
  def change
    add_column :electorates_postcodes, :population, :integer
    add_column :electorates_postcodes, :total_postcode_population, :integer
    add_column :electorates_postcodes, :proportion, :decimal
  end
end
