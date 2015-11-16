class AlterMergeRecordsJoinId < ActiveRecord::Migration
  def change
    change_column :merge_records, :join_id, :string
  end
end
