class Auxiliary < ActiveRecord::Migration
	def self.up
		execute "TRUNCATE schema_migrations;"
		execute "INSERT INTO schema_migrations VALUES ('20141204040236');"

		# add_start_time_to_user_calls from post-flatten merge (otherwise rails tries to re-run it)
		execute "INSERT INTO schema_migrations VALUES ('20150212010446');"
	end
	def self.down
		raise ActiveRecord::IrreversibleMigration
	end
end
