desc 'Decode a csv of tokens and append a column of emails (replace email_token_salt to the production value in config/constants.yml)'
task :decode_tokens, [:csv_file_name] => [:environment] do |t, args|
  file_name = args[:csv_file_name]
  decoded_file_name = "decoded_#{file_name}"
  CSV.open("db/csv/#{decoded_file_name}", "w+", :headers => true) do |output|
    CSV.foreach("db/csv/#{file_name}", :headers => true, :return_headers => true) do |row|
      if row.header_row?
        output << (row << 'user_id')
      else
        data = EmailTrackingToken.decode(row['Token'])
        output << (row << data[:userid])
      end
    end
  end
  puts "Output in db/csv/#{decoded_file_name}"
end
