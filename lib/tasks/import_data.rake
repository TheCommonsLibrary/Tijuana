require_relative 'electoral_data_importer'

namespace :import do

  task :home_page => :environment do
    unless Homepage.count > 0
      Homepage.create!(
          :banner_text => "{MEMBERCOUNT} AUSSIES WHO ALL FIGHT FOR FAIRNESS, SUSTAINABILITY & SOCIAL JUSTICE!",
          :campaign_image => "/images/homepage-campaign1-placeholder.jpg",
          :campaign_url => "/donate",
          :campaign_alt_text => "Donate to GetUp!",
          :campaign2_image => "/images/homepage-campaign2-placeholder.jpg",
          :campaign2_url => "/donate",
          :campaign2_alt_text => "Donate to GetUp!",
          :campaign3_image => "/images/homepage-campaign3-placeholder.jpg",
          :campaign3_url => "/donate",
          :campaign3_alt_text => "Donate to GetUp!"
      )
    end
  end

  desc "Import static themes"
  task :themes => :environment do
    Theme.delete_all
    Theme.create!(:name => "application", :display_name => "Default", :id => 1)
    Theme.create!(:name => "communityrun", :display_name => "CommunityRun", :id => 2)
    Theme.create!(:name => "pokies", :display_name => "Pokies Personal Stories", :id => 10)
    Theme.create!(:name => "out-of-sight", :display_name => "Out of Sight", :id => 12)
    Theme.create!(:name => "no_branding", :display_name => "No Branding", :id => 14)
    Theme.create!(name: 'openletter', display_name: 'Open Letter', id: 20)
    Theme.create!(name: 'heroes', display_name: 'Heroes', id: 21)
    Theme.create!(name: 'map', display_name: 'Map', id: 22)
    Theme.create!(name: 'nbia', display_name: 'No Business In Abuse', id: 23)
    Theme.create!(name: 'embed', display_name: 'Embed', id: 25)
    Theme.create!(name: 'daisy_chain', display_name: 'Daisy Chain', id: 27)
    Theme.create!(name: 'getup2018', display_name: 'Getup 2018', id: 2018)
    puts "Themes added: #{Theme.count}"
  end

  namespace :electoral do
    desc "importing postcodes and related data"
    task :data => :environment do
      ElectoralDataImporter.new("db/csv").import_electoral_data
    end

    desc "Import all MP data"
    task :mps => :environment do
      ElectoralDataImporter.new("db/csv").import_mps
    end
    
    desc "Import all senator data"
    task :senators => :environment do
      ElectoralDataImporter.new("db/csv").import_senators
    end
    
    desc "Import postcode data" 
    task :postcodes => :environment do
      ElectoralDataImporter.new("db/csv").import_postcodes
    end

    desc "Import party data for all jurisdictions" 
    task :parties => :environment do
      ElectoralDataImporter.new("db/csv").import_parties
    end

    desc "Import regions_postcodes only" 
    task :regions_postcodes => :environment do
      ElectoralDataImporter.new("db/csv").import_regions_postcodes
    end

    desc "Import electorates only"
    task :electorates => :environment do
      ElectoralDataImporter.new("db/csv").import_electorates
    end

    desc "Import electorate_postcodes only" 
    task :electorates_postcodes => :environment do
      ElectoralDataImporter.new("db/csv").import_electorates_postcodes
    end
  end
end
