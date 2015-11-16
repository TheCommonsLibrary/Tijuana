namespace :create_events do
  require 'csv'
  
  desc "Import batch geo-coded Harvey Norman stores"
  task :import_nhn_events => :environment do
    CSV.open('db/csv/harvey_norman_get_togethers.csv','r').each do |row|
      event = Event.new(
        :name => row[0],
        :address => row[1],
        :street => row[2],
        :suburb => row[3],
        :postcode => row[4],
        :address_latitude => row[5],
        :address_longitude => row[6],
        :confirmed => row[7],
        :confirmed_at => row[8],
        :created_at => row[9],
        :updated_at => row[10],
        :date => GetTogether.find(2).to_date,
        :time => GetTogether.find(2).to_time,
        :host_id => User.find(row[13]),
        :get_together_id => GetTogether.find(2),
        :capacity => row[15],
        :is_public => row[16],
        :terms_and_conditions => row[17]
      )
      success = event.save
      puts "Failed to import event with name #{event.name}: #{event.errors.first}" unless success
    end
  end
end