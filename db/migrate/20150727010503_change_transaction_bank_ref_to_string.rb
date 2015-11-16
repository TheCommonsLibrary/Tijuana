class ChangeTransactionBankRefToString < ActiveRecord::Migration
  def change
    change_column :transactions, :bank_ref, :string
  end
end
