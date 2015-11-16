class CreateQuarantineTable < ActiveRecord::Migration
  def change
    create_table :quarantines do |t|
      t.integer :user_id
      t.timestamps
    end
    add_index :quarantines, :user_id, unique: true
  end
end
