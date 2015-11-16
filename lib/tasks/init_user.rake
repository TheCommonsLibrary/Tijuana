require 'yaml'

namespace :db do
  desc "init the db user"
  task :init_user => :environment do
    DATABASE_DETAILS = YAML.load(ERB.new(Rails.root.join('config', 'database.yml').read).result)
    create_user_command = "create user \"#{DATABASE_DETAILS['development_readonly']['username']}\"@\"localhost\" identified by \"#{DATABASE_DETAILS['development_readonly']['password']}\";"
    grant_select_on_development = " grant select on #{DATABASE_DETAILS['development']['database']}.* to \"#{DATABASE_DETAILS['development_readonly']['username']}\"@\"localhost\";"
    grant_select_on_v2 = " grant select on v2.* to \"#{DATABASE_DETAILS['development_readonly']['username']}\"@\"localhost\";"

    ActiveRecord::Base.connection.execute(create_user_command)
    ActiveRecord::Base.connection.execute(grant_select_on_development)
    ActiveRecord::Base.connection.execute(grant_select_on_v2)
  end
end
