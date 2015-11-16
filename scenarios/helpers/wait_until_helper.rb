module WaitUntilHelper
  def wait_until(wait_time = Capybara.default_max_wait_time)
    require "timeout"
    Timeout.timeout(wait_time) do
      sleep(0.1) until value = yield
      value
    end
  end
end

# this helper is used in cucumbers and rspec scenarios
RSpec.configuration.include WaitUntilHelper, :type => :feature if defined?(::RSpec)
World(WaitUntilHelper) if respond_to?(:World)
