namespace :import do
  desc 'Import tags to be associated with campaigns from a CSV file in db/csv. Usage: import:campaign_tags[campaign_tags.csv]'
  task :campaign_tags, [:csv_file_name] => :environment do |t, args|
    CSV.foreach("db/csv/#{args[:csv_file_name]}", :headers => true) do |row|
      tags = row['tags']
      if !tags.blank? && campaign = Campaign.find_by_id(row['campaign_id'])
        campaign.tag_list.add(tags, parse: true)
        campaign.save!
      end
    end
  end
end
