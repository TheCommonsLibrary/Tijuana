module CacheDbHelper
  def cache_db
    path = "#{Rails.root}/tmp/db_cache/#{self.class.description.parameterize}"
    
    if File.exists? "#{path}/db_cache.yml"
      YamlDb::SerializationHelper::Base.new(YamlDb::Helper).load "#{path}/db_cache.yml"
      ActionMailer::Base.deliveries = YAML.load File.read("#{path}/deliveries.yml")
    else
      yield
      FileUtils::mkdir_p path
      File.open("#{path}/deliveries.yml", 'w') { |f| f.write(YAML.dump ActionMailer::Base.deliveries) }
      YamlDb::SerializationHelper::Base.new(YamlDb::Helper).dump("#{path}/db_cache.yml")
    end
  end
end

RSpec.configure do |config|
  config.include CacheDbHelper, :type => :feature
  
  config.before :all do
    FileUtils.rm_rf Dir.glob("tmp/db_cache/#{self.class.description.parameterize}/*")
  end
end
