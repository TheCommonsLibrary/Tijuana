namespace :content do
  desc 'import the most recent snapshot of the production CMS content into the dev database'
  task :import => :environment do
    FILENAME = "tijuana_content_snapshot_for_dev.sql"
    LOCAL_FILEPATH = Rails.root.join('db' ,'content', FILENAME).to_s

    if ENV['CONTENT']
      rails_env = ENV['ENVIRONMENT'] || 'development'

      puts "Importing content into #{rails_env} database..."

      if File.exists? File.join(Rails.root, 'config', 'database.yml')
        db_details = Rails.configuration.database_configuration[rails_env]

        host = rails_env == 'showcase' ? "-h #{db_details['host']}" : ''
        password = db_details['password'].blank? ? "" : "--password=\"#{db_details['password']}\""
        %x{mysql --user=#{db_details['username']} #{password} -D #{db_details['database']} #{host} < #{LOCAL_FILEPATH}}
        drop_tables current_push_tables
        clear_tables tables_to_clear
        puts "Done!"
      end
    else
      raise 'Run rake content:import CONTENT=true to run this task, sorry for the inconvenience'
    end
  end
end

def current_push_tables
  ActiveRecord::Base.connection.tables.select {|table| table =~ /push_\d+/ }
end

def tables_to_clear
  %w{
      blasts bookmarked_content_modules delayed_jobs donations emails failed_donations
      petition_signatures push_logs sent_emails transactions transparency_metrics user_activity_events
      user_calls user_emails
  }
end

def clear_tables(tables)
  tables.each do |table|
    ActiveRecord::Base.connection.execute "DELETE FROM #{table};"
  end
end

def drop_tables(tables)
  tables.each do |table|
    ActiveRecord::Base.connection.execute "DROP TABLE IF EXISTS #{table};"
  end
end
