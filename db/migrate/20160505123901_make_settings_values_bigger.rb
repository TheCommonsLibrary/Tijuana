class MakeSettingsValuesBigger < ActiveRecord::Migration
  def change
    change_table :settings do |t|
      t.change :value, :text
    end
  end
end
