ENV["RAILS_ENV"] ||= 'test'
require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'
require "email_spec"
require 'webmock/rspec'
WebMock.allow_net_connect!(allow_localhost: true)

Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| require f}

RSpec.configure do |config|
  config.raise_errors_for_deprecations!
  config.mock_with :rspec
  config.fixture_path = "#{::Rails.root}/spec/fixtures"
  config.use_transactional_fixtures = true
  config.include(EmailSpec::Helpers)
  config.include(EmailSpec::Matchers)
  config.include FactoryGirl::Syntax::Methods
  config.before(:suite) { DatabaseCleaner.clean_with :truncation }
  config.expose_current_running_example_as :example
  config.infer_spec_type_from_file_location!
  config.mock_with(:rspec) { |mocks| mocks.yield_receiver_to_any_instance_implementation_blocks = false }
  config.mock_with(:rspec) { |mocks| mocks.syntax = [:should, :expect] }
  config.expect_with(:rspec) { |expect| expect.syntax = [:should, :expect] }

  if ENV['RUNNING_GUARD']
    config.filter_run :focus => true
    config.run_all_when_everything_filtered = true
  end
end

def read_fixture(name)
  IO.readlines("#{::Rails.root}/spec/fixtures/#{name}")
end

# Custom matchers
[:same_array_regardless_of_order, :be_same_array_regardless_of_order].each do |matcher_name|
  RSpec::Matchers.define matcher_name do |expected|
    match do |actual|
      expected.sort == actual.sort
    end
  end
end

def without_transactional_fixtures(&block)

  before(:all) do
    @old_use_transactional_fixtures = self.use_transactional_fixtures
    self.class.use_transactional_fixtures = false
    DatabaseCleaner.strategy = :truncation, {cache_tables: false}
  end

  after(:each) do
    DatabaseCleaner.clean
  end

  after(:all) do
    DatabaseCleaner.strategy = :transaction
    self.class.use_transactional_fixtures = @old_use_transactional_fixtures
  end

  yield

end

def with_push_table(*pushes)
  yield
ensure
  Push.all.each do |p|
    p.drop_activities_table
  end
end

def create_simple_email(options={})
  user = options[:user] || create(:leo)
  email = options[:email] || create(:email)
  email
end
