class AddPaymentGatewayToTransactions < ActiveRecord::Migration
  def change
    add_column :transactions, :gateway_name, :string
    execute "update transactions inner join donations on transactions.donation_id = donations.id set gateway_name = 'SecurePay' where donations.payment_method = 'credit_card'"
  end
end
