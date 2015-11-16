namespace :hospital_merge do
  desc 'Import hospital merge data from csv'
  task :import => :environment do
    failed_records = []
    index = 0

    merge = Merge.find_or_create_by_name 'hospitals'
    merge.update_attribute(:join_key, 'postcode_id')
    puts merge

    puts 'Removing merge records for "hospitals"'
    merge.merge_records.destroy_all

    puts 'Creating merge records'
    hospitals = {}
    CSV.foreach('hospitals.csv', :headers => true) do |row|
      name = row['HOSPITAL NAME {CF}']
      funding = row['FUNDING CUTS {CF}']
      link = row['PETITION LINK {CF}']
      electorate = row['ELECTORATE {CF}']
      puts "Added electorate #{electorate}"
      hospitals[electorate] = [name, funding]
    end

    database = Rails.configuration.database_configuration[Rails.env]["database"]

    sql = <<-SQL
      SELECT p.district, p.postcode, pc.id FROM scratch.federal_2013_electorates_postcodes p
      JOIN (
        SELECT postcode, max(elector_proportion) AS maxp
        FROM scratch.federal_2013_electorates_postcodes
        GROUP BY postcode
      ) AS max_postcode ON max_postcode.postcode = p.postcode AND max_postcode.maxp = p.elector_proportion
      JOIN #{database}.postcodes pc ON pc.number = p.postcode
      ORDER BY postcode ASC
    SQL

    postcodes = ActiveRecord::Base.connection.execute(sql)
    postcodes.each do |p|
      postcode_id = p[2]
      electorate = p[0]
      record = hospitals[electorate]
      if record.nil?
        puts "** Unable to find CSV record for electorate: #{electorate}"
        next
      end

      begin
        MergeRecord.create!(name: 'name', value: record[0], merge: merge, join_id: postcode_id.to_i) 
        MergeRecord.create!(name: 'funding', value: record[1], merge: merge, join_id: postcode_id.to_i) 
        MergeRecord.create!(name: 'link', value: link, merge: merge, join_id: electorate) 
      rescue => e
        puts "Unable to create record. name: #{name}, value: #{funding}, join_id: #{electorate}"
        puts e
      end
    end

    puts 'Done!'
  end
end
