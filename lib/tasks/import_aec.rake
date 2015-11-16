require 'set'

namespace :import do
  namespace :aec do

    ELECTORATE_CSV = 'db/csv/02-2014-LO15_National_D140205_reformatted.csv'
    POSTCODE_CSV = 'db/csv/02-2014-postcodes_from_sensis.csv'
    FEDERAL_NSW = 2
    FEDERAL_ACT = 7
    FEDERAL_VIC = 6
    FEDERAL_QLD = 1
    FEDERAL_SA = 5
    FEDERAL_WA = 3
    FEDERAL_TAS = 8
    FEDERAL_NT = 4
    STATE_NSW = 38
    STATE_SA = 39

    task :all_postcode_mappings => %w(delete_electorates_postcodes import_postcodes sed fed sup fup sup_nsw_sa)

    desc 'Update electorates until 10/2/2014'
    task :prepare_electorates_20140210 => :environment do
      rename_electorates
      delete_old_electorates
    end

    def rename_electorates
      north_west = Electorate.find_by_name('North West')
      north_west.name = 'North West Central'
      north_west.save!
    end

    def delete_old_electorates
      names = ['GetUp', 'Macdonnell', 'Nollamara', 'Blackwood Stirling', 'Mindarie']
      names.each do |e|
        electorate = Electorate.find_by_name(e)
        if electorate != nil
          electorate.delete
          puts "Deleted: #{electorate.name}"
        end
      end
    end

    desc 'Delete tables'
    task :delete_electorates_postcodes => :environment do
      ActiveRecord::Base.connection.execute('DELETE FROM electorates_postcodes')
      ActiveRecord::Base.connection.execute('DELETE FROM postcodes_regions')
    end

    desc 'Import or update postcode data'
    task :import_postcodes => :environment do
      existing_postcodes = Hash[Postcode.select('number, id').map { |p| [p.number, p.id.to_i] }]
      CSV.open(POSTCODE_CSV, 'r').each do |row|
        if !row[1].nil? && !row[2].nil?
          number = normalise_postcode_number(row[0])
          if existing_postcodes[number].nil?
            create_new_postcode(number, row[1], row[2])
          else
            update_lat_long(existing_postcodes[number], row[1], row[2])
          end
        end
      end
    end

    def create_new_postcode(number, lat, long)
      begin
        postcode = Postcode.create!(:number => number, :latitude => lat, :longitude => long)
        puts "Created new postcode #{postcode.number}"
      rescue
        puts "Failed to create new postcode with number: #{number}"
      end
    end

    def update_lat_long(id, lat, long)
      begin
        postcode = Postcode.find(id)
        postcode.latitude = lat
        postcode.longitude = long
        postcode.save!
      rescue
        puts "Failed to update postcode with id: #{id}"
      end
    end

    desc 'SED: Import state lower house electorate postcode data'
    task :sed => :environment do
      CSV.open(ELECTORATE_CSV, 'r').each do |row|
        if row[1].strip == 'SED'
          jurisdiction = Jurisdiction.find_by_code(row[0].strip)
          electorate = Electorate.find_or_create_by_name_and_jurisdiction_id(row[4].strip.titleize, jurisdiction.id)
          postcode_number = normalise_postcode_number(row[3])
          save_postcode_relationship(electorate, postcode_number)
        end
      end
    end

    desc 'FED: Import federal lower house electorate postcode data'
    task :fed => :environment do
      CSV.open(ELECTORATE_CSV, 'r').each do |row|
        if row[1].strip == 'FED'
          jurisdiction = Jurisdiction.find_by_code('FEDERAL')
          electorate = Electorate.find_by_name_and_jurisdiction_id(row[4].strip.titleize, jurisdiction.id)
          if electorate.nil?
            electorate = Electorate.create!(:name => row[4].strip.titleize, :jurisdiction_id => jurisdiction.id)
          end
          postcode_number = normalise_postcode_number(row[3])
          save_postcode_relationship(electorate, postcode_number)
        end
      end
    end

    desc 'SUP: Import state upper house electorate postcode data'
    task :sup => :environment do
      CSV.open(ELECTORATE_CSV, 'r').each do |row|
        if row[1].strip == 'SUP'
          jurisdiction = Jurisdiction.find_by_code(row[0].strip)
          region = Region.find_or_create_by_name_and_jurisdiction_id(row[4].strip.titleize, jurisdiction.id)
          postcode_number = normalise_postcode_number(row[3])
          save_postcode_relationship(region, postcode_number)
        end
      end
    end

    desc 'FUP: Import federal upper house postcode mappings'
    task :fup => :environment do
      Postcode.all.each do |p|
        region_id = get_federal_region_id(p.number)
        region = Region.find(region_id)
        save_postcode_relationship(region, p.number)
      end
    end

    desc 'SUP: Import NSW and SA state upper house electorate postcode data'
    task :sup_nsw_sa => :environment do
      nsw = Region.find(STATE_NSW)
      sa = Region.find(STATE_SA)
      state_regions = {STATE_NSW => nsw, STATE_SA => sa}
      Postcode.all.each do |p|
        region_id = get_state_region_id(p.number)
        if state_regions.keys.include? region_id
          save_postcode_relationship(state_regions[region_id], p.number)
        end
      end
    end

    def get_federal_region_id(postcode)
      ranges = {FEDERAL_NSW => [(1000..1999),(2000..2599),(2619..2899),(2921..2999)],
                FEDERAL_VIC => [(3000..3999),(8000..8999)],
                FEDERAL_ACT => [(200..299),(2600..2618),(2900..2920)],
                FEDERAL_QLD => [(4000..4999),(9000..9999)],
                FEDERAL_SA => [(5000..5799),(5800..5999)],
                FEDERAL_WA => [(6000..6799),(6800..6999)],
                FEDERAL_TAS => [(7000..7799),(7800..7999)],
                FEDERAL_NT => [(800..999)]}
      ranges.keys.each do |k|
        ranges[k].each do |r|
          return k if r.include?(postcode.to_i)
        end
      end
      'NOT FOUND'
    end

    def get_state_region_id(postcode)
      ranges = {STATE_NSW => [(1000..2599),(2619..2899),(2921..2999)],
                STATE_SA => [(5000..5799),(5800..5999)]}
      ranges.keys.each do |k|
        ranges[k].each do |r|
          return k if r.include?(postcode.to_i)
        end
      end
      'NOT FOUND'
    end

    def normalise_postcode_number(postcode_number)
      postcode_number = "0#{postcode_number}" if postcode_number.length < 4
      postcode_number
    end

    def save_postcode_relationship(electorate, postcode_number)
      postcode = Postcode.find_by_number(postcode_number)
      begin
        unless electorate.postcodes.include?(postcode)
          electorate.postcodes << postcode
          electorate.save!
        end
      rescue
        puts "No postcode found with number: #{postcode_number} for electorate id: #{electorate.id}"
      end
    end
  end

  desc 'Count electorate to postcode mappings'
  task :count_electorates_to_postcode_mappings => :environment do
    types = { 'SED' => {}, 'FED' => {}, 'SUP' => {} }
    postcodes_to_ignore = postcodes_without_geocode
    CSV.open(ELECTORATE_CSV, 'r').each do |row|
      unless types[row[1]].nil?
        types[row[1]][row[4]] = Set.new if types[row[1]][row[4]].nil?
        types[row[1]][row[4]].add(row[3]) unless postcodes_to_ignore.include?(row[3])
      end
    end
    print_counts(types)
  end

  def print_counts(types)
    types.keys.each do |t|
      puts "#{t}\nelectorates: #{types[t].keys.size}"
      postcode_count = 0
      types[t].keys.each { |k| postcode_count += types[t][k].size }
      puts "postcodes: #{postcode_count}"
    end
  end

  def postcodes_without_geocode
    postcodes = Set.new
    CSV.open(POSTCODE_CSV, 'r').each do |row|
      if row[1].nil? || row[2].nil?
        postcodes.add(row[0].strip)
      end
    end
    postcodes
  end
end