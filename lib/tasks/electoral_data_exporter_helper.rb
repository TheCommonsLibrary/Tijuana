class ElectoralDataExporterHelper
  TABLES = [
    'mps',
    'parties',
    'electorates',
    'regions',
    'senators',
    'jurisdictions',
    'postcodes',
    'postcodes_regions',
    'electorates_postcodes'
  ]

  def initialize(exported_directory, database_username, database_password, database_name)
    @exported_directory = exported_directory
    @database_username = database_username
    @database_password = database_password
    @database_name = database_name
  end

  def mysql_commands
    mysql_commands = []
    TABLES.each do |table|
      mysql_commands << "mysql --user=#{@database_username} --password=\"#{@database_password}\" #{@database_name} -e \"select * from #{table}\" | sed 's/^/\"/g;s/$/\"/g;s/\\\t/\",\"/g;s/\"NULL\"//g' > #{file_path(@exported_directory, table)}" # sed command will put double quote around the column's values
    end
    mysql_commands
  end

  def exported_files
    exported_files = []
    TABLES.each do |table|
      exported_files << table + '.csv'
    end
    exported_files
  end

  private

  def file_path(directory, table_name)
    directory + '/' + table_name + '.csv'
  end
end
