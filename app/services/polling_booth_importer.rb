module PollingBoothImporter
  module_function

  def import_booth(row)
    extract_booth_data(row) do |polling_booth|
      polling_booth[:electorate] = get_electorate(row['DivName'])
      PollingBooth.create!(polling_booth)
    end
  end

  def import_pre_booth(row)
    extract_booth_data(row) do |polling_booth|
      booth = PrePollingBooth.find_or_initialize_by_premises_name(row['PremisesName'])
      if booth.new_record?
        booth = PrePollingBooth.create!(polling_booth)
      end
electorate = get_electorate(row['DivName'])
      booth.electorates << electorate unless booth.electorates.include?(electorate)
      hours = {from_date: row['DateFrom'].to_date, to_date: row['DateTo'].to_date, from_time: row['TimeFrom'], to_time: row['TimeTo']}
      booth.hours << hours unless booth.hours.include?(hours) || hours[:from_date] == Date.new(2016, 7, 2)
      booth.save!
    end
  end

  def extract_booth_data(row)
    unless row['Status'] == 'Abolition'
      address = [row['Address1'], row['Address2'], row['Address3']].select(&:present?).join("\n")

      if (row['Lat'].blank? || row['Long'].blank?) && address.present?
        geo = calc_geo([address, row['Locality'], row['Postcode']].compact.join(', '))
        geo = calc_geo([row['Postcode'], row['Locality']].compact.join(", ")) if geo.empty?
        row['Lat'] = geo[:latitude]
        row['Long'] = geo[:longitude]
      end

      polling_booth = {
        premises_name: row['PremisesName'],
        address: address,
        suburb: row['Locality'].present? ? row['Locality'].titleize : "",
        postcode: Postcode.find_by_number(row['Postcode']),
        latitude: row['Lat'].to_f,
        longitude: row['Long'].to_f,
        booth_location: row['AdvBoothLocation'],
        booth_gate: row['AdvGateAccess'],
        booth_entrance: row['EntrancesDesc'].try(:slice, 0, 255),
        wheelchair: row['WheelchairAccess']
      }
      yield polling_booth
    end
  end

  def get_electorate(name)
    Electorate.where({name: name, jurisdiction_id: Jurisdiction.find_by_name('Federal')}).first
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

