class AddGetup2018Theme < ActiveRecord::Migration
  def up
    Theme.create!(name: 'getup2018', display_name: 'Getup 2018', id: 2018)
  end

  def down
    Theme.find(2018).destroy
  end
end
