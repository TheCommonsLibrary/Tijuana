class AddPinnedShownTitleBlurbExpiryToPageSequences < ActiveRecord::Migration
  def change
    add_column :page_sequences, :pillar_pin, :boolean, default: false
    add_column :page_sequences, :pillar_show, :boolean, default: true
    add_column :page_sequences, :title, :text, :limit => 21
    add_column :page_sequences, :blurb, :text, :limit => 140
    add_column :page_sequences, :expired, :boolean, :default => false
    add_column :page_sequences, :expires_at, :datetime
    add_column :page_sequences, :expired_redirect_page_sequence_id, :integer
  end
end
