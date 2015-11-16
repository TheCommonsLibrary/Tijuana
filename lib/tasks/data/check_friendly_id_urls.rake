namespace :data do
  desc "hit every friendly_id url from 'tmp/paths.txt'"
  task :check_friendly_id_urls => :environment do
    session = ActionDispatch::Integration::Session.new(Rails.application)
    session.host! "www.example.com"

    results = File.open("#{Rails.root}/tmp/path_results.txt", "w")

    File.foreach("#{Rails.root}/tmp/paths.txt") do |line|
      begin
        result = session.head line.strip
        results.write "#{result} :: #{line}"

        # use `rake data:check_friendly_id_urls > /dev/null` to see only this output
        STDERR.puts   "#{result} :: #{line}"
      rescue
        results.write "ERROR:: #{line}"
        STDERR.puts   "ERROR:: #{line}"
      end
    end
  end
end
