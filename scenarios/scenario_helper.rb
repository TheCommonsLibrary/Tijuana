# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= 'test'
ENV["SCENARIO_SPECS"] = 'true'
require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'
require 'rspec/autorun'
require 'webmock/rspec'
require 'rake'
require 'jasmine_rails/rspec'
WebMock.allow_net_connect!(allow_localhost: true)

require_relative '../spec/support/shared_contexts/system_io'
Dir[Rails.root + "scenarios/helpers/*.rb"].each { |file| require file }
Dir[Rails.root + "scenarios/support/*.rb"].each { |file| require file }


# Work around to allow quick donate cookie on HTTP for scenario tests only
require 'quickdonate_helper'
module QuickdonateHelper
  def use_secure_cookies?
    false
  end
end

# By default, allow all http connections otherwise we will need to stub other connections (e.g. solr).
#WebMock.allow_net_connect!

RSpec.configure do |config|
  config.expose_current_running_example_as :example
  config.infer_spec_type_from_file_location!

  config.expect_with(:rspec) { |c| c.syntax = [:expect, :should] }

# Not required yet to load seed data
#  config.before :suite do
#
#    rake = Rake::Application.new
#    Rake.application = rake
#    Rake::Task.define_task(:environment)
#    load "#{Rails.root}/lib/tasks/import_data.rake"
#    rake["import:home_page"].invoke
#
#    MemberCountCalculator.init
#  end


  # == Mock Framework
  #
  # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr
  config.mock_with :rspec

  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  #config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = false

  config.before(:suite) { DatabaseCleaner.clean_with :truncation }

  config.before :each do
    Rails.cache.clear
    DatabaseCleaner.strategy = :truncation, {cache_tables: false}
  end

  config.after :each do
    DatabaseCleaner.clean
  end

  # If true, the base class of anonymous controllers will be inferred
  # automatically. This will be the default behavior in future versions of
  # rspec-rails.
  #config.infer_base_class_for_anonymous_controllers = false

  if ENV['RUNNING_GUARD']
    config.filter_run :focus => true
    config.run_all_when_everything_filtered = true
  end
  
  config.include IRB::ExtendCommandBundle
  # config.include EmailSpec::Helpers
  # config.include EmailSpec::Matchers
  
  config.include FactoryGirl::Syntax::Methods
end

def with_push_table
  yield
ensure
  Push.all.each do |p|
    p.drop_activities_table
  end
end
