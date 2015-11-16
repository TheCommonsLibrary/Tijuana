class AddAccountsKey < ActiveRecord::Migration
  def up
    add_column(:campaigns, :accounts_key, :string) unless column_exists?(:campaigns, :accounts_key)
  end

  def down
    remove_column(:campaigns, :accounts_key) if column_exists?(:campaigns, :accounts_key)
  end
end
