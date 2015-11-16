require 'yaml'
require 'fileutils'

RAILS_ROOT = File.expand_path(File.join(File.dirname(__FILE__), '..', '..'))
CREDENTIALS_PATH = ENV['CREDENTIALS_PATH'] || File.expand_path(File.join(RAILS_ROOT, '..'))

namespace :credentials do
  desc 'Prepare deployment credentials'
  task :prepare do
    CREDENTIALS_REPO = YAML.load_file(File.join(RAILS_ROOT, 'config', 'constants.yml'))[Rails.env]['credentials_repository']
    REPO_NAME = CREDENTIALS_REPO.match(/[^\/]+(?=\.git)/).to_s

    puts "I'm about to clone the credentials repo into #{CREDENTIALS_PATH}..."

    fail_on_error "cd #{CREDENTIALS_PATH} && git clone #{CREDENTIALS_REPO}"
    fail_on_error "ln -s #{File.expand_path(File.join(CREDENTIALS_PATH, REPO_NAME))} #{File.join(RAILS_ROOT, 'servers', 'credentials')}"
    fail_on_error "chmod 600 #{File.expand_path(File.join(RAILS_ROOT, 'servers', 'credentials', 'keys', '*.pem'))}"
  end

  desc 'Install config files necessary for our development environment'
  task :install_development do
    copy_config_files
  end

  private

  def fail_on_error(cmd)
    raise "TASK FAILED (#{cmd})" unless system(cmd)
  end

  def copy_config_files
    config_src_files = Dir.glob File.expand_path(File.join(RAILS_ROOT, 'servers', 'credentials', 'environments', 'development', '**'))
    config_dest_dir = File.expand_path(File.join(RAILS_ROOT, 'config'))

    FileUtils.cp config_src_files, config_dest_dir
  end
end
