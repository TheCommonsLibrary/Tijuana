require 'capybara/rspec'
require 'capybara/poltergeist'
require 'headless'

Capybara.default_max_wait_time = 5

Capybara.register_driver :poltergeist_debug do |app|
  Capybara::Poltergeist::Driver.new(app, :inspector => true, :timeout => 10000, :phantomjs_logger => StringIO.new, :phantomjs_options => ['--load-images=no', '--ignore-ssl-errors=yes', '--ssl-protocol=any'])
end
Capybara.javascript_driver = ENV['CAPYBARA_DRIVER'].nil? || ENV['CAPYBARA_DRIVER'].blank? ? :poltergeist_debug : ENV['CAPYBARA_DRIVER'].to_sym


Headless.new(:display => Process.pid, :reuse => false).start

ActionController::Base.asset_host = Capybara.app_host

# TODO: Rick, 2011-12-20 - RSpec 2.7.0 and Capybara 1.1.2 do not handle exit codes from invoked processes as expected.
# The upshot of this is that when capybara-webkit runs its end of suite browser teardown (exit 0) it masks any failing scenarios (exit 1).
# When an official patch makes it into either gem we should be able to remove ebeigart's workaround.
# https://github.com/jnicklas/capybara/pull/463#issuecomment-1887393
module Kernel
  alias :__at_exit :at_exit

  def at_exit(&block)
    __at_exit do
      exit_status = $!.status if $!.is_a?(SystemExit)
      block.call
      exit exit_status if exit_status
    end
  end
end
