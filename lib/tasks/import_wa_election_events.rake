namespace :import do

  desc "Import WA election 2014 events from specified CSV for specified get together id. E.g. rake import:wa_events[15, db/csv/wa_election_events.csv]"
  task :wa_events, [:get_together_id, :csv_file] => [:environment] do |t, args|

    def create_event(row, get_together_id)
      address = address(row)
      event = Event.new(
        name: row['Name'],
        date: DateTime.strptime(row['Date(dd/mm/yy)'].to_s, "%d/%m/%y"),
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
        address_latitude: row['Latitude'],
        address_longitude: row['Longitude'],
        suburb_latitude: row['Latitude'],
        suburb_longitude: row['Longitude'],
        confirmed_at: Time.now,
        confirmation_code: nil)
      save_ignoring_date_error(event)
    end

    def save_ignoring_date_error(event)
      event.valid?
      if event.errors.size == 1 && event.errors.has_key?(:date)
        event.save!(validate: false)
      else
        event.save!
      end
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

    failed_records = []
    index = 0
    begin
      puts "Importing to get together with ID = #{args[:get_together_id]}"
      CSV.foreach(args[:csv_file], :headers => true) do |row|
        begin
          lat = nil
          long = nil
          create_event(row, GetTogether.find(args[:get_together_id]))
          puts "Event imported: #{index}"
        rescue Exception => e
          failed_records << row.to_hash
          puts "Failed to import event: #{index} - #{e.message}"
        ensure
          index += 1
        end
      end
      display_failed_records(failed_records) if failed_records.present?
    rescue Exception => e
      puts clean_data_beforehand
      puts e.message
    end
  end
end
