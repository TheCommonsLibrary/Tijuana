class UpdatePageSequencesNameVarcharLength < ActiveRecord::Migration
  def change
    change_column :page_sequences, :name, :string, :limit => 218
  end
end
