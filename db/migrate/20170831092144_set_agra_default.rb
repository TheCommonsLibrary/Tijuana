class SetAgraDefault < ActiveRecord::Migration
  def up
    change_column_default :users, :is_agra_member, false
  end

  def down
    change_column_default :users, :is_agra_member, true
  end
end
