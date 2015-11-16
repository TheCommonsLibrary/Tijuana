namespace :import do

  desc "Import rally events from rally_events.csv for specified get together id. E.g. rake import:rally_events[15]"
  task :rally_events, [:get_together_id] => [:environment] do |t, args|
    failed_records = []
    index = 0

    begin
      CSV.foreach('db/csv/rally_events.csv', :headers => true) do |row|
        begin
          puts "Importing to get together with ID = #{args[:get_together_id]}"
          import_row(row, GetTogether.find(args[:get_together_id]))
          puts "Rally event imported: #{index}"
        rescue Exception => e
          failed_records << row.to_hash
          puts "Failed to import rally event: #{index} - #{e.message}"
        ensure
          index += 1
        end
      end
      puts "Data Imported!"
      display_failed_records(failed_records) if failed_records.present?
    rescue Exception => e
      puts clean_data_beforehand
      puts e.message
    end
  end

  def import_row(row, get_together_id)
    address = address(row)

    Event.create!(
        name: row['Name'],
        date: DateTime.strptime(row['Date(dd/mm/yy'].to_s, "%d/%m/%y"),
        time: row['Time'].split(':').shift(2).join(''),
        address: address,
        host: User.find_by_email(row['HostEmail']),
        host_notes: row['Notes'],
        get_together: get_together_id,
        capacity: row['Capacity'],
        phone: row['Phone'],
        postcode: row['Postcode'],
        street: row['StreetAddress'],
        suburb: row['Suburb'],
        address_latitude: row['Lat'],
        address_longitude: row['Long'],
        suburb_latitude: row['Lat'],
        suburb_longitude: row['Long'],
        confirmed_at: Time.now,
        confirmation_code: nil,
    )
  end

  def address(row)
    address = ""
    address << row['StreetAddress'] if row['StreetAddress'].present?
    address << "\n" << row['Suburb'] if row['Suburb'].present?
    address << " " << row['Postcode'] if row['Postcode'].present?
    address
  end

  def display_failed_records(failed_records)
    puts "Total number of events failed: #{failed_records.count}"
    puts "Following events not imported:"
    failed_records.each {|event_row|  puts event_row}
  end

end
