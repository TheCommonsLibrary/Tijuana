class AlterImageShareCaption < ActiveRecord::Migration
  def change
    change_table :image_shares do |t|
      t.change :caption, :text
    end
  end
end
