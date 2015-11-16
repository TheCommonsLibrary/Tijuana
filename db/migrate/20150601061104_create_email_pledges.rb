class CreateEmailPledges < ActiveRecord::Migration
  def change
    create_table :email_pledges do |t|
      t.integer :content_module_id
      t.integer :user_id
      t.integer :user_email_id
      t.string :target_email
      t.string :target_name

      t.timestamps
    end
  end
end
