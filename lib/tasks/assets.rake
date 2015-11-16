task :precompile_test_assets do
  fail_on_error('rake assets:clobber assets:precompile RAILS_ENV=test')
end

task :clean_test_assets do
  #slow - fail_on_error('rake assets:clean RAILS_ENV=test')
  # faster hard coded one below
  fail_on_error("rm -rf #{Rails.root.join("public-test", "assets")}")
end

def fail_on_error(cmd)
  raise "TASK FAILED (#{cmd})" unless system(cmd)
end
