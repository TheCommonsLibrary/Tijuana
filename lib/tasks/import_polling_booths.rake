namespace :import do
  desc "prepare polling_booths csv"
  task :prepare_polling_booths_csv, :csv_file do |_, args|
    puts "Reading & quote-escaping #{args[:csv_file]}"
    csv = File.open(args[:csv_file]) {|f| f.read.gsub(/(?<!^|,)"(?!,|\R)/, '""') }
    puts "Validating CSV content"
    CSV.parse(csv)
    output_file = 'db/csv/polling_booths.csv'
    IO.write(output_file, csv, universal_newline: true)
    puts "output written to #{output_file}"
  end

  desc "Clear then import polling booths from db/csv/polling_booths.csv"
  task :polling_booths => :environment do
    PollingBooth.delete_all
    failed_records = []
    CSV.foreach('db/csv/polling_booths.csv', headers: true).with_index(2) do |row, line_number|
      begin
        PollingBoothImporter.import_booth(row)
        print '.'
      rescue Exception => e
        failed_records << {line: line_number, name: row['PremisesName'], err: e.message}
      end
    end
    puts;puts "done. booths not imported:"
    puts failed_records.map{|r| [r[:line].to_s.ljust(5), r[:name].ljust(60), r[:err]].join(' ') }.join("\n")
  end
end
