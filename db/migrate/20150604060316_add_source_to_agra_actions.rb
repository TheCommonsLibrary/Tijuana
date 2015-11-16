class AddSourceToAgraActions < ActiveRecord::Migration
  def change
    add_column :agra_actions, :source, :string
  end
end
