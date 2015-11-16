class AddAccountsKeyIndexToCampaigns < ActiveRecord::Migration
  def change
    add_index :campaigns, :accounts_key
  end
end
