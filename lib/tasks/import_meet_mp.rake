namespace :import do

  desc "Import meet mp events for specified get together id. E.g. rake import:meet_mp[15]"
  task :meet_mp, [:get_together_id] => [:environment] do |t, args|

    def create_event(row, get_together_id, lat, long)
      event = Event.new(
        name: row['Name'],
        date: DateTime.strptime(row['Date(dd/mm/yy)'].to_s, "%d/%m/%y"),
        time: row['Time'],
        address: row['StreetAddress'],
        host: User.find_by_email(row['HostEmail']),
        host_notes: row['Notes'],
        get_together: get_together_id,
        capacity: row['Capacity'],
        phone: row['Phone'],
        postcode: row['Postcode'],
        street: row['Street'],
        suburb: row['Suburb'],
        address_latitude: lat,
        address_longitude: long,
        suburb_latitude: lat,
        suburb_longitude: long,
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

    def display_failed_records(failed_records)
      puts "Total number of events failed: #{failed_records.count}"
      puts "Following events not imported:"
      failed_records.each {|event_row|  puts event_row}
    end

    def calc_geo(location)
      begin
        geo_coordinates = Geocoder.search(location)
        { latitude: geo_coordinates[0].latitude, longitude: geo_coordinates[0].longitude }
      rescue Exception => e
        {}
      end
    end

    failed_records = []
    index = 0
    begin
      puts "Importing to get together with ID = #{args[:get_together_id]}"
      CSV.foreach('db/csv/import_mp_events.csv', :headers => true) do |row|
        begin
          lat = nil
          long = nil
          full_address = row['StreetAddress']
          if full_address.present?
            geo = calc_geo(full_address)
            geo = calc_geo([row['Postcode'], row['Suburb']].compact.join(', ')) if geo.empty?
            lat = geo[:latitude]
            long =  geo[:longitude]
          end
          create_event(row, GetTogether.find(args[:get_together_id]), lat, long)
          puts "Meet MP imported: #{index}"
        rescue Exception => e
          failed_records << row.to_hash
          puts "Failed to import meet MP: #{index} - #{e.message}"
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
