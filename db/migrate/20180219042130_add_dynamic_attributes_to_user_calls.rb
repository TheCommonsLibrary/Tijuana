class AddDynamicAttributesToUserCalls < ActiveRecord::Migration
  def change
    add_column :user_calls, :dynamic_attributes, :text
  end
end
