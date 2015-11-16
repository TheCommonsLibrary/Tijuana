class AlterElectoratesPostcodesTableProportionType < ActiveRecord::Migration
  def change
    change_column :electorates_postcodes, :proportion, :decimal, :precision => 3, :scale => 2
  end
end
