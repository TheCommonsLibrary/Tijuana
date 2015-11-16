namespace :member do
  class PutsProgress
    def initialize(name, total)
      @name = name
      @total = total
      @index = 0
    end
    
    def inc
      @index += 1
      puts "#{@name}: #{((@index.to_f / @total.to_f) * 100.0).round(2)}%" if @index % 100 == 0
    end
  end
  
  task :generate => :environment do
    all_old_tags = 1.upto(10_000).map { SecureRandom.hex(10) }
    
    File.open('members2.csv', 'w') do |f|
      1.upto(3_000_000) do |n|
        email = "#{SecureRandom.hex(16)}@testingtags"
        old_tags = all_old_tags.select { rand(200) == 0 }.join(",")
        
        line = [email, old_tags].map { |s| %{"#{s}"} }.join(",")
        f.puts line
        puts "#{((n.to_f / 3_000_000) * 100.0).round(2)}%" if n % 100 == 0
      end
    end
    
    # load members
    ActiveRecord::Base.connection.execute "LOAD DATA INFILE '#{Rails.root}/members.csv' INTO TABLE users FIELDS TERMINATED BY ',' ENCLOSED BY '\"' (email, old_tags) SET id = NULL;"
  end
  
  task :migrate_old_tags => :environment do
    # find unique set of old tags
    tag_by_name = {}
    
    in_mem_progress = PutsProgress.new('extract old tags from db', User.count)
    File.open('taggings.csv', 'w') do |f|
      User.find_each(:batch_size => 10_000) do |user|
        next unless user.old_tags.present?
        in_mem_progress.inc
        user.old_tags.split(',').map(&:strip).each do |tag|
          unless tag_by_name.key?(tag)
            tag_by_name[tag] = ActsAsTaggableOn::Tag.where(:name => tag).first_or_create.id
          end
          f.puts [tag_by_name[tag], user.id, 'User', 'labels'].join(",")
        end
      end
    end
    
    
    # load taggings
    puts "import taggings into db"
    ActiveRecord::Base.connection.execute "LOAD DATA INFILE '#{Rails.root}/taggings.csv' INTO TABLE taggings FIELDS TERMINATED BY ',' (tag_id, taggable_id, taggable_type, context) SET id = NULL, created_at = now();"
  end
end


