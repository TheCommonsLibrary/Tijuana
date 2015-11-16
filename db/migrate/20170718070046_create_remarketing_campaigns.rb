class CreateRemarketingCampaigns < ActiveRecord::Migration
  def change
    create_table :remarketing_campaigns do |t|
      t.text :content, null: false
      t.boolean :active, default: false
      t.text :tags, null: false
      t.timestamps
    end
    add_index :remarketing_campaigns, :active
  end
end
