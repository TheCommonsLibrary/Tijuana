require 'rubygems'

begin
  namespace :ci do
    desc "wake up S-buildbox EC2 instance"
    task :start do
      puts `cd ./servers; rake cloud:start NAME=S-buildbox`
    end

    desc "Run only spec"
    task :specs => [:spec]

    desc "Run only slow specs"
    RSpec::Core::RakeTask.new(:specs_slow) do |t|
      t.rspec_opts = "--tag speed:slow"
    end if defined?(RSpec)

    desc "Run all scenarios in parallel, and run jasmine tests"
    task :scenarios_parallel => [:precompile_test_assets, :scenario_parallel, 'spec:javascript']

    task :scenario_parallel do
      `parallel_rspec -n 2 #{FileList['./scenarios/*.rb'].exclude("./scenarios/scenario_helper.rb").include('./scenarios/integration/*.rb').join(" ")}`
      raise "tests failed!" unless $? == 0
    end

    desc "Run all scenarios & jasmine tests"
    task :scenarios => [:precompile_test_assets, :scenario, 'spec:javascript']

    desc "Run legacy cucumber features"
    task :features => [:precompile_test_assets, :cucumber]

    desc "Run slow specs & jasmine"
    task :misc => [:specs_slow, 'spec:javascript']

    namespace :parallel do
      desc "Run non-slow specs in parallel"
      task :specs => ['parallel:spec']

      desc "Run all scenarios in parallel"
      task :scenarios => [:precompile_test_assets] do
        sh "parallel_rspec #{FileList['./scenarios/*.rb'].exclude("./scenarios/scenario_helper.rb").include('./scenarios/integration/*.rb').join(" ")}"
      end

      desc "Run legacy cucumber features in parallel"
      task :features => [:precompile_test_assets, 'rake:parallel:features']
    end
  end
end
