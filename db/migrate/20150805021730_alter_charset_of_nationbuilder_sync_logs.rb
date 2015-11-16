class AlterCharsetOfNationbuilderSyncLogs < ActiveRecord::Migration
  def up
    execute 'ALTER TABLE nationbuilder_sync_logs CONVERT TO CHARACTER SET utf8 COLLATE utf8_general_ci'
  end

  def down
    execute 'ALTER TABLE nationbuilder_sync_logs CONVERT TO CHARACTER SET latin1'
  end
end
