require_relative "../google_importer"

namespace :import do
  desc "Import candidates & issues from Google Sheets. Usage: `rake import:election_data`"
  task :election_data => :environment do |t, args|
    ActiveRecord::Base.transaction do
      Candidate.delete_all
      Issue.delete_all
      google_importer = GoogleImporter.new
      google_importer.import("candidates")
        .each{|candidate| Candidate.serialized_create(candidate) }
      google_importer.import("electorates_web")
        .select{|issue| issue["issue"] }
        .map{|issue| issue.merge("slug" => issue["seat"].downcase.gsub(/ /, '-')) }
        .each{|issue| Issue.serialized_create(issue) }
    end
  end
end
