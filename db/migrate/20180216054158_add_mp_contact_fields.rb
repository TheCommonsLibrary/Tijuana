class AddMpContactFields < ActiveRecord::Migration
  def change
    add_column :mps, :mailing_address, :text
    add_column :mps, :mailing_suburb, :text
    add_column :mps, :mailing_state, :text
    add_column :mps, :mailing_postcode, :text
  end
end
