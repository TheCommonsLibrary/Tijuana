class ChangePillarDisplayDefault < ActiveRecord::Migration
  def change
    change_column :page_sequences, :pillar_show, :boolean, default: false
  end
end
