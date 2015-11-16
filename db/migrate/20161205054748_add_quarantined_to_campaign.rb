class AddQuarantinedToCampaign < ActiveRecord::Migration
  def change
    add_column :campaigns, :quarantined, :boolean
  end
end
