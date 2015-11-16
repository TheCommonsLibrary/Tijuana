source "https://rubygems.org"

gem 'dotenv-rails', groups: [:development, :test]

# for the RAILS4 upgrade only - remove eventually
gem "protected_attributes" # replace with strong params or similar
gem "actionpack-action_caching" # for `caches_action` in ActivityController
gem "rails-observers" # PageSweeper
gem "activerecord-deprecated_finders", require: "active_record/deprecated_finders" # for .find(:all, conditions: {})

gem "nokogiri" # first, to ensure it loads correct libxml
gem "rails", "4.2.7.1"
gem "hashids"
gem "mysql2"
gem 'haml-rails'
gem 'exception_notification'
gem "will_paginate"
gem "paranoia"
gem 'acts_as_list'
gem 'acts-as-taggable-on'
gem 'delayed_job'
gem 'delayed_job_active_record'
gem 'sendgrid', '0.1.4'
gem "paperclip"
gem "fog-aws"
gem 'rmagick'
gem "activemerchant", github: "GetUp/active_merchant", branch: "production"
gem "devise"
gem 'two_factor_authentication'
gem 'devise_security_extension'
gem 'cancan'
gem "jquery-rails" #RAILS4 do we need this?
gem 'friendly_id', "~> 5.0"
gem 'w3c_validators'
gem 'app_constants'
gem "geokit-rails"
gem "acts_as_commentable_with_threading", "1.2.0" #RAILS4 leave until rails4
gem 'gritter', '0.6.3'
gem 'validates_email_format_of'
gem 'geocoder'  #currently only used for import:events rake task
gem 'httpclient'
gem 'excon'
gem 'google-api-client', '0.9'
gem 'google_drive'
gem 'puma'

gem 'fb_graph', :require=>false
gem 'handlebars_assets', '0.4.0'

gem "lograge", github: "getup/lograge", ref: "mirror-logging"
gem "best_in_place"
gem "rumoji", github: "GetUp/rumoji" # emoji codec
gem 'vanity'
gem 'mail_view'
gem 'auto_strip_attributes'
gem "nationbuilder-rb", git: 'git://github.com/nationbuilder/nationbuilder-rb.git', ref: 'd2382d17d6172dfcdff181bfadd4f059c11fe728', require: "nationbuilder"
gem 'addressable' # used to prevent errors with parsing NationBuilder urls
gem 'scrypt'

gem 'uglifier'
gem 'compass-rails'
gem 'sass-rails', '~> 4.0.5'

gem 'active_model_serializers' #used to serialize active model objects eg. page sequences for api request

group :test do
  gem "coffee-rails"
end

group :production, :showcase do
  gem 'newrelic_rpm', '>= 3.7.0.177'
  gem 'dalli'
  gem 'connection_pool' # for Dalli when using multithreaded server
end

group :development, :showcase do
  gem 'net-ssh'
  gem 'net-scp'
end

group :development do
  gem 'sprinkle' # causes lots of extra logging output, so no good for test
  gem 'terminal-table'
  gem 'capistrano_colors'
  gem 'foreman'
  gem "meta_request" # install RailsPanel in chrome
  gem "rack-livereload"
  gem 'guard-livereload', require: false
end

group :development, :test do
  gem "parallel_tests"
  gem 'rspec-rails', '3.4.1'
  gem 'rspec-its'
  gem 'rspec-collection_matchers'
  gem 'selenium-webdriver'
  gem 'launchy'
  gem 'capybara'
  gem 'cucumber-rails', '1.4.5', :require => false
  gem 'factory_girl_rails'
  gem 'email_spec'
  gem 'thin'
  gem 'database_cleaner'
  gem 'jasmine'
  gem 'pry'
  gem 'pry-doc'
  gem 'pry-byebug'
  gem 'awesome_print'
  gem 'guard-rspec'
  gem 'fuubar'
  gem 'spring'
  gem 'spring-commands-rspec'
  gem "guard-jasmine"
  gem 'jasmine-jquery-rails'
  gem 'jasmine-rails'
  gem 'json', github: 'flori/json', branch: 'v1.8' # waiting for fix to be released: http://stackoverflow.com/questions/41298904/is-it-possible-to-run-a-rails-4-2-app-on-ruby-2-4
end

group :test do
  gem 'headless', '0.2.2'            # required by ubuntu ci server for capybara webkit testing
  gem 'capybara-mechanize'
  gem 'capybara-webkit'
  gem 'poltergeist'
  gem 'rack-test'
  gem 'timecop'
  gem 'net-http-digest_auth'
  gem 'webmock', :require => false
  gem 'rainbow'
  gem 'irake'
  gem 'yaml_db'
  gem 'vcr'
end
