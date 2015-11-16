# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('../config/application', __FILE__)
require 'rake'
require 'rake/dsl_definition'
require 'rubygems'

include Rake::DSL

begin
  task :faster => ['parallel:prepare', 'parallel:spec', :scenario, 'spec:javascript']

  namespace :test do

    desc "Run fast build (for pre-checkin, fast_build on build server)"
    task :fast => [:spec, :scenario, 'spec:javascript']

    desc "Ensure assets are precompiled before jasmine tests"
    task :javascript => [:precompile_test_assets] do
      fail_on_error('rake spec:javascript')
    end

    private

    def fail_on_error(cmd)
      raise "Could not complete task #{cmd}" unless system(cmd)
    end
  end

rescue LoadError
end

Tijuana::Application.load_tasks

task :default => 'test:fast'

task :putsenv do
  pp ENV, STDERR
end
