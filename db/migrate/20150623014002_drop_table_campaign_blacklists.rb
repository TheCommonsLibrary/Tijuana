class DropTableCampaignBlacklists < ActiveRecord::Migration
  def up
    drop_table :campaign_blacklists
  end

  def down
    create_table :campaign_blacklists, id: false do |t|
      t.integer  :user_id
      t.integer  :campaign_id
      t.datetime :created_at,  null: false
      t.datetime :updated_at,  null: false
    end

    add_index :campaign_blacklists, [:user_id, :campaign_id], name: :user_campaign_idx
  end
end
