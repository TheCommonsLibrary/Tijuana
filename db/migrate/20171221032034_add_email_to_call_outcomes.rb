class AddEmailToCallOutcomes < ActiveRecord::Migration
  def change
    add_column :call_outcomes, :email, :string, after: :user_id
  end
end
