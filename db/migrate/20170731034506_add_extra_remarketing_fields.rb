class AddExtraRemarketingFields < ActiveRecord::Migration
  def change
    add_column :remarketing_campaigns, :priority, :integer, default: 0
  end
end
