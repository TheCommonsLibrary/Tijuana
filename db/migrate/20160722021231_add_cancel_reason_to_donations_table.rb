class AddCancelReasonToDonationsTable < ActiveRecord::Migration
  def change
    add_column :donations, :cancel_reason, :string
    add_column :donations, :cancelled_at, :datetime
  end
end
