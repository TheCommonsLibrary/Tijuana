desc "Migrates push data from the user activity events table into individual tables"

namespace :pushes do

  def create_push_table(push_id)
    print "Creating table for push #{push_id}"
    create_push_table_sql = <<HERE
    CREATE TABLE IF NOT EXISTS `push_#{push_id}` (
      `user_id` int(11) NOT NULL,
      `activity` varchar(64) NOT NULL,
      `email_id` int(11) NOT NULL,
      `created_at` DATETIME,
      KEY `activity_idx` (`activity`),
      KEY `email_idx` (`email_id`),
      KEY `user_idx` (`user_id`),
      KEY `user_activity_idx` (`user_id`,`activity`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8;
HERE
    Push.connection.execute(create_push_table_sql)
    puts "...done"
  end

  def get_email_ids_from_push(push_id)
    print "Retrieving the email ids belonging to push #{push_id}"
    email_ids_from_push_sql = <<HERE
select e.id
from pushes p
join blasts b
  on p.id = b.push_id
join emails e
  on b.id = e.blast_id
where p.id = #{push_id};
HERE

    email_ids = Push.connection.execute(email_ids_from_push_sql).to_a.flatten
    puts "...done"
    email_ids
  end

  def migrate_push_data_into_push_table(email_ids, push_id)
    print "Migrating push data from user activity events into the push table #{push_id}"
    migrate_from_activities_into_push_sql = <<HERE
    insert into push_#{push_id}
    select user_id, activity, email_id, created_at
    from user_activity_events
    where email_id in(#{email_ids.join(",")})
    and activity in ('email_sent', 'email_viewed', 'email_clicked');
HERE

    Push.connection.execute(migrate_from_activities_into_push_sql)
    puts "...done"
  end

  #def clear_migrated_push_data(push_id, email_ids)
  #  print "Removing migrated data from user_activity_events"
  #  delete_sql = <<HERE
  #  delete from user_activity_events
  #  where email_id in(#{email_ids.join(",")})
  #  and activity = 'email_sent';
  #HERE
  #  Push.connection.execute(delete_sql)
  #  puts "...done"
  #end


    def migrate_push_data(push_id) 
      ActiveRecord::Base.transaction do
        truncate_sql = "TRUNCATE TABLE push_#{push_id}"
        Push.connection.execute(truncate_sql)
        email_ids = get_email_ids_from_push(push_id)
        next if email_ids.blank?
        migrate_push_data_into_push_table(email_ids, push_id)
        # Commented out until we can safely empty out the user activity events table
        #clear_migrated_push_data(push_id, email_ids)
        puts "Done processing push #{push_id}."
      end
    end

    task :create_tables_and_fill => :environment do
      push_ids = Push.select(:id).all.map(&:id)
      push_ids.each_with_index do |push_id, idx|
        create_push_table(push_id)
        puts "Processing push #{push_id} (#{idx} of #{push_ids.size})"
        migrate_push_data(push_id)
      end
    end

    task :delete_tables => :environment do
      push_ids = Push.select(:id).all.map(&:id)
      push_ids.each do |push_id|
        puts "Dropping table 'push_#{push_id}'"
        delete_push_table_sql = "DROP TABLE IF EXISTS `push_#{push_id}`"
        Push.connection.execute(delete_push_table_sql)
      end
    end


    task :refresh_table => :environment do
      push_id = ENV['PUSH_ID']
      puts "Dropping table 'push_#{push_id}'"
      delete_push_table_sql = "DROP TABLE IF EXISTS `push_#{push_id}"
      Push.connection.execute(delete_push_table_sql)
      puts "Creating table 'push_#{push_id}'"
      create_push_table(push_id)
      migrate_push_data(push_id)
    end

    task :create_tables => :environment do
      push_ids = Push.select(:id).all.map(&:id)
      push_ids.each_with_index do |push_id, idx|
        create_push_table(push_id)
      end
    end
  end


