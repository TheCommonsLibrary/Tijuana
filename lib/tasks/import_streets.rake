namespace :import do

  desc "Import street information from csv called streets.csv"
  task :streets => :environment do 
    CSV.open('db/csv/streets.csv', 'r').each do |row|
      Street.create!(name: titleise(row[0]), suburb_name: titleise(row[1])) unless row[1].blank?
    end
    puts "Done!"
  end

  def titleise(name) 
    name = name.titleize
    name[2] = name[2].upcase if name.start_with?("O'")
    name
  end
end
