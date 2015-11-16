if Rails.env.development? || Rails.env.test?

  require 'rubygems'
  require 'rspec/core/rake_task'

  desc "Run all scenario tests"
  RSpec::Core::RakeTask.new(:scenario => [:precompile_test_assets]) do |t|
    t.pattern = FileList['./scenarios/*.rb'].exclude("./scenarios/scenario_helper.rb").include('./scenarios/integration/*.rb')
  end
end
