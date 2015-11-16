require 'csv'

namespace :import do

  desc "Clear then import pre polling booths from db/csv/pre_polling_booths.csv"
  task :pre_polling_booths, [:csv_file] => :environment do |t, args|
    PrePollingBooth.delete_all
    failed_records = []
    csv_file = args[:csv_file] || 'db/csv/pre_polling_booths.csv'
    CSV.foreach(csv_file, headers: true) do |row, line_number|
      begin
        PollingBoothImporter.import_pre_booth(row)
        print '.'
      rescue Exception => e
        failed_records << {line: line_number, name: row['PremisesName'], err: e.message}
      end
    end
    puts;puts "done. booths not imported:"
    puts failed_records.map{|r| [r[:line].to_s.ljust(5), r[:name].ljust(60), r[:err]].join(' ') }.join("\n")
  end
end
