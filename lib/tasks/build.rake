namespace :build do
  desc "For build to creates a tagged release on the master branch. Usage: rake build:tag BUILD_NO=XXX"
  task :tag do
    puts "\nNOTE: THIS WILL PUSH ALL YOUR COMMITTED CHANGES TO DEVELOP - Ctrl-C to stop!\n"
    build_no = ENV['BUILD_NO']
    raise "Specify BUILD_NO=XXX" unless build_no
    tag_name = "goodbuild-" + build_no

    on_tmp_branch do |tmp_branch_name|
      Rake::Task["build:create_commit_assets"].execute
      fail_on_error "git tag #{tag_name}"
      fail_on_error "git push origin #{tag_name}"
    end
  end

  desc "Build assets and commit them. This task should only be run on the build box."
  task :create_commit_assets do
    fail_on_error 'rake assets:clean RAILS_ENV=production'
    fail_on_error 'rake assets:precompile RAILS_ENV=production'

    fail_on_error 'git add -f public/assets'
    tolerate_error 'git commit -m "Packaged assets."'
  end
end

private

def fail_on_error(cmd)
  raise "DEPLOYMENT FAILED (#{cmd})" unless system(cmd)
end

def tolerate_error(cmd)
  puts "Command '#{cmd}' returned non-zero." unless system(cmd)
end

def on_tmp_branch(&block)
  rev = current_checkout
  tmp_branch_name = "tmp_deployment_workspace_#{Time.now.to_i}"
  fail_on_error "git checkout -b #{tmp_branch_name}"
  yield(tmp_branch_name)
  fail_on_error "git checkout #{rev}"
  fail_on_error "git branch -D #{tmp_branch_name}"
end

def current_checkout
  current_hash = `git rev-parse HEAD`
  current_branch_name = /\* (.*)$/.match(`git branch`).captures.first
  (current_branch_name =~ /\(/) ? current_hash : current_branch_name
end

