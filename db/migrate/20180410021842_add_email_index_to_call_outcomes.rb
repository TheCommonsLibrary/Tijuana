class AddEmailIndexToCallOutcomes < ActiveRecord::Migration
  def change
    add_index :call_outcomes, :email
  end
end
