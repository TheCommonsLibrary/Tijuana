desc 'add open letter theme to "australians for action" campaign'
task :add_openletter_theme => :environment do
  theme = Theme.find_or_create_by_name(name: 'openletter', display_name: 'Open Letter', id: 20)
  puts "Created theme: #{theme.name} (display name: #{theme.display_name})"
  campaign = Campaign.find_or_create_by_name('Australians for Action')
  campaign.theme = theme
  campaign.save!
  puts "Updated theme for #{campaign.name}!"
end

