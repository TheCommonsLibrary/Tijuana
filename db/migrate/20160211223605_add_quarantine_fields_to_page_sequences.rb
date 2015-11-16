class AddQuarantineFieldsToPageSequences < ActiveRecord::Migration
  def change
    add_column :page_sequences, :welcome_email_disabled, :boolean
    add_column :page_sequences, :quarantined, :boolean
  end
end
