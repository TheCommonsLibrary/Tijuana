require 'csv'

class ElectoralSeeder
  def self.seed_electoral_data
    CSV.open('db/csv/test/jurisdictions.csv', 'r', :headers => true).each_with_index do |row, index|
      Jurisdiction.create(:name => row['name'], :code => row['code'], :upper_house_present => row['upper_house_present']) do |jurisdiction|
        jurisdiction.id = row['id']
      end
    end

    CSV.open('db/csv/test/parties.csv', 'r', :headers => true).each_with_index do |row, index|
      Party.create(:name => row['name'], :abbreviation => row['abbreviation'], :jurisdiction_id => row['jurisdiction_id']) do |party|
        party.id = row['id']
      end
    end

    CSV.open('db/csv/test/postcodes.csv', 'r', :headers => true).each_with_index do |row, index|
      Postcode.create(:number => row['number'], :state => row['state'], :longitude => row['longitude'], :latitude => row['latitude']) do |postcode|
        postcode.id = row['id']
      end
    end

    CSV.open('db/csv/test/electorates.csv', 'r', :headers => true).each_with_index do |row, index|
      Electorate.create(:name => row['name'], :jurisdiction_id => row['jurisdiction_id']) do |electorate|
        electorate.id = row['id']
      end
    end

    CSV.open('db/csv/test/regions.csv', 'r', :headers => true).each_with_index do |row, index|
      Region.create!(:name => row['name'], :jurisdiction_id => row['jurisdiction_id']) do |region|
        region.id = row['id']
      end
    end

    CSV.open('db/csv/test/postcodes_regions.csv', 'r', :headers => true).each_with_index do |row, index|
      region = Region.find(row['region_id'])
      region.postcodes << Postcode.find(row['postcode_id']) unless row['postcode_id'] == '0'
      region.save!
    end

    CSV.open('db/csv/test/electorates_postcodes.csv', 'r', :headers => true).each_with_index do |row, index|
      electorate = Electorate.find(row['electorate_id'])
      electorate.postcodes << Postcode.find(row['postcode_id'])
      electorate.save!
    end

    CSV.open('db/csv/test/mps.csv', 'r', :headers => true).each_with_index do |row, index|
      Mp.create(:last_name => row['last_name'],
                :first_name => row['first_name'],
                :email => row['email'],
                :parliament_phone => row['parliament_phone'],
                :parliament_fax => row['parliament_fax'],
                :office_address => row['office_address'],
                :office_state => row['office_state'],
                :office_postcode => row['office_postcode'],
                :office_fax => row['office_fax'],
                :office_phone => row['office_phone'],
                :party_id => row['party_id'],
                :electorate_id => row['electorate_id']) do |mp|
                  mp.id = row['id']
                end
    end

    CSV.open('db/csv/test/senators.csv', 'r', :headers => true).each_with_index do |row, index|
      Senator.create(
          :first_name => row['first_name'],
          :last_name => row['last_name'],
          :email => row['email'],
          :state => row['state'],
          :party_id => row['party_id'],
          :office_address => row['office_address'],
          :office_suburb => row['office_suburb'],
          :office_state => row['office_state'],
          :office_postcode => row['office_postcode'],
          :office_phone => row['office_phone'],
          :office_fax => row['office_fax'],
          :parliament_phone => row['parliament_phone'],
          :parliament_fax => row['parliament_fax'],
          :mailing_address => row['mailing_address'],
          :mailing_suburb => row['mailing_suburb'],
          :mailing_state => row['mailing_state'],
          :mailing_postcode => row['mailing_postcode'],
          :region_id => row['region_id']
      ) do |senator|
        senator.id = row['id']
      end
    end
  end
end
