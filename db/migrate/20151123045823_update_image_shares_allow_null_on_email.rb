class UpdateImageSharesAllowNullOnEmail < ActiveRecord::Migration
  def change
    change_column :image_shares, :email_id, :integer, :null => true
  end
end
