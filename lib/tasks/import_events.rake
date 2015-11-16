namespace :import do

  desc "Import event information from csv called events.csv"
  task :events => :environment do
    failed_records = []
    index = 0

    CSV.foreach('db/csv/events.csv', :headers => true) do |row|
      
      location = [row['Address1'], row['Locality'], row['Postcode']].compact.join(", ")
      if (row['Lat'].blank? || row['Long'].blank?) && location.present?
        geo = calc_geo(location)
        geo = calc_geo([row['Postcode'], row['Locality']].compact.join(", ")) if geo.empty?
        row['Lat'] = geo[:latitude]
        row['Long'] = geo[:longitude]
      end

      begin
        event = Event.create!(
            name: row['PremisesName'],
            date: DateTime.strptime(row['Date(dd/mm/yy)'].to_s, "%d/%m/%y"),
            time: row['Time'].split(':').shift(2).join(''),
            address: location,
            host: User.find_by_email(row['HostEmail']),
            host_notes: row['EntrancesDesc'],
            get_together: GetTogether.find(row['GetTogetherId'].to_i),
            capacity: row['Capacity'],
            phone: row['Phone'],
            postcode: row['Postcode'],
            street: location,
            suburb: row['Locality'],
            address_latitude: row['Lat'],
            address_longitude: row['Long'],
            suburb_latitude: row['Lat'],
            suburb_longitude: row['Long'],
            confirmed_at: Time.now,
            confirmation_code: nil,
        )

        index += 1
        puts "Event imported: #{index}"

        UserActivityEvent.registered_to_host! event.host, event
      rescue Exception => e
        puts e
        index += 1
        failed_records << row.to_hash
        puts "Failed to import event: #{index}"
      end
    end

    puts "Data Imported!"
    display_failed_records(failed_records) if failed_records.present?
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
end
