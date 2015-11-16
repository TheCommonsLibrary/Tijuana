class CreateDonationUpgrades < ActiveRecord::Migration
  def change
    create_table :donation_upgrades do |t|
      t.string :donation_id
      t.integer :original_amount_in_cents
      t.integer :upgrade_amount_in_cents
      t.integer :content_module_id
      t.timestamps
    end
  end
end
