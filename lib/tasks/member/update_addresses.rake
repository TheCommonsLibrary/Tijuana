require 'updated_addresses/update_address_service'
require 'updated_addresses/updated_address_row'

namespace :member do
  desc 'Update member address records and address_validated_at based on CSV file passed in. E.g. rake member:update_address[addresses_140805.csv]'
  task :update_address, [:csv_file_name] => [:environment] do |t, args|
    index = 0
    CSV.open("db/csv/#{args[:csv_file_name]}",'r', :headers => true).each do |row|
      begin
        record_row = UpdatedAddressRow.new(row)
        UpdateAddressService.update_records record_row
      rescue Exception => e
        puts "Failed to update user: #{index} - #{e.message}"
      ensure
        index += 1
      end
    end
  end
end
