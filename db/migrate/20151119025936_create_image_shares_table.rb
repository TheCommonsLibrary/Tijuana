class CreateImageSharesTable < ActiveRecord::Migration
  def up
    create_table :image_shares do |t|
      t.integer  "user_id",            :null => false
      t.integer  "content_module_id",  :null => false
      t.integer  "page_id",            :null => false
      t.integer  "email_id",            :null => false
      t.string  "image_url",            :null => false
      t.string  "caption",            :null => false
      t.timestamps
    end
  end
end
