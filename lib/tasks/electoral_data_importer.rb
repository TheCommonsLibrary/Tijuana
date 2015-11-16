class ElectoralDataImporter
  def initialize(data_directory)
    @data_directory = data_directory
  end

  def import_electoral_data
    # sidestep foreign key constraints
    empty_mps
    empty_electorates_postcodes
    empty_electorates
    empty_postcodes_regions
    empty_regions

    import_jurisdictions
    import_parties
    import_postcodes
    import_electorates
    import_regions
    import_regions_postcodes
    import_electorates_postcodes
    import_mps
    import_senators
  end

  def import_mps
    puts "Importing MPs"
    CSV.foreach(@data_directory + '/mps.csv', :headers => true) do |row|
      Mp.create!(:last_name => row['last_name'],
                 :first_name => row['first_name'],
                 :email => row['email'],
                 :parliament_phone => row['parliament_phone'],
                 :parliament_fax => row['parliament_fax'],
                 :office_address => row['office_address'],
                 :office_suburb => row['office_suburb'],
                 :office_state => row['office_state'],
                 :office_postcode => row['office_postcode'],
                 mailing_address: row['mailing_address'],
                 mailing_suburb: row['mailing_suburb'],
                 mailing_state: row['mailing_state'],
                 mailing_postcode: row['mailing_postcode'],
                 :office_fax => row['office_fax'],
                 :office_phone => row['office_phone'],
                 :party_id => row['party_id'],
                 :electorate_id => row['electorate_id']) do |mp|
        mp.id = row['id']
      end
    end
  end

  def import_parties
    puts "Deleting existing parties"
    Party.delete_all

    puts "Importing parties"
    CSV.foreach(@data_directory + '/parties.csv', :headers => true) do |row|
      Party.create!(:name => row['name'], :abbreviation => row['abbreviation'], :jurisdiction_id => row['jurisdiction_id']) do |party|
        party.id = row['id']
      end
    end
  end

  def import_senators
    puts "Deleting senators"
    Senator.delete_all

    puts "Importing senators"
    CSV.foreach(@data_directory + '/senators.csv', :headers => true) do |row|
      Senator.create!(
          :last_name => row['last_name'],
          :first_name => row['first_name'],
          :email => row['email'],
          :state => row['state'],
          :parliament_phone => row['parliament_phone'],
          :parliament_fax => row['parliament_fax'],
          :office_address => row['office_address'],
          :office_suburb => row['office_suburb'],
          :office_state => row['office_state'],
          :office_postcode => row['office_postcode'],
          :office_fax => row['office_fax'],
          :office_phone => row['office_phone'],
          :mailing_address => row['mailing_address'],
          :mailing_suburb => row['mailing_suburb'],
          :mailing_state => row['mailing_state'],
          :mailing_postcode => row['mailing_postcode'],
          :party_id => row['party_id'],
          :region_id => row['region_id']
      ) do |senator|
        senator.id = row['id']
      end
    end
  end

  def import_electorates_postcodes
    puts "Importing electorate postcodes"
    CSV.foreach(@data_directory + '/electorates_postcodes.csv', :headers => true) do |row|
      electorate = Electorate.find(row['electorate_id'])
      electorate.postcodes << Postcode.find(row['postcode_id']) unless row['postcode_id'] == '0'
      electorate.save!
      if %w[population total_postcode_population proportion].all?{|field| row[field].present? }
        Electorate.connection.execute(
          "update electorates_postcodes set "\
          "population=#{row['population']},"\
          "total_postcode_population=#{row['total_postcode_population']},"\
          "proportion=#{row['proportion']} "\
          "where electorate_id=#{row['electorate_id']} and postcode_id=#{row['postcode_id']}"
        )
      end
    end
  end

  def import_postcodes
    puts "Deleting existing postcodes"
    Postcode.delete_all

    puts "Importing postcodes"
    CSV.foreach(@data_directory + '/postcodes.csv', :headers => true) do |row|
      Postcode.create!(:number => row['number'], :state => row['state'], :longitude => row['longitude'], :latitude => row['latitude']) do |postcode|
        postcode.id = row['id']
      end
    end
  end

  def import_regions_postcodes
    puts "Importing regions postcodes"
    CSV.foreach(@data_directory + '/postcodes_regions.csv', :headers => true) do |row|
      region = Region.find(row['region_id'])
      region.postcodes << Postcode.find(row['postcode_id']) unless row['postcode_id'] == '0'
      region.save!
    end
  end

  def import_electorates
    puts "Importing electorates data"
    CSV.foreach(@data_directory + '/electorates.csv', :headers => true) do |row|
      Electorate.create!(:name => row['name'], :jurisdiction_id => row['jurisdiction_id']) do |electorate|
        electorate.id = row['id']
      end
    end
  end

  private

  def import_jurisdictions
    puts "Deleting existing jurisdictions"
    Jurisdiction.delete_all

    puts "Importing jurisdictions data"
    CSV.foreach(@data_directory + '/jurisdictions.csv', :headers => true) do |row|
      Jurisdiction.create!(:name => row['name'], :upper_house_present => row['upper_house_present'], :code => row['code']) do |jurisdiction|
        jurisdiction.id = row['id']
      end
    end
  end

  def import_regions
    puts "Importing Regions data"
    CSV.foreach(@data_directory + '/regions.csv', :headers => true) do |row|
      Region.create!(:name => row['name'], :jurisdiction_id => row['jurisdiction_id']) do |region|
        region.id = row['id']
      end
    end
  end

  def empty_mps
    puts "Deleting MPs"
    Mp.delete_all
  end

  def empty_electorates_postcodes
    puts 'deleting existing electorates_postcodes'
    ActiveRecord::Base.connection.execute('DELETE FROM electorates_postcodes')
  end

  def empty_postcodes_regions
    puts 'Deleting existing postcodes_regions'
    ActiveRecord::Base.connection.execute('DELETE FROM postcodes_regions')
  end

  def empty_electorates
    puts "Deleting existing electorates"
    Electorate.delete_all
  end

  def empty_regions
    puts "Deleting existing regions"
    Region.delete_all
  end

end
