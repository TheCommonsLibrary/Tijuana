RSpec.configure do |config|
  config.after do
    if Capybara.page.current_url.present? && example.exception && example.metadata[:focus] && ENV['RUNNING_GUARD']
      puts example.exception.message.red
      ConsoleBacktraceCleaner.new.clean(example.exception.backtrace).each { |s| puts s.yellow }
      binding.pry
    elsif Capybara.page.current_url.present? && example.exception
      Capybara.page.save_screenshot "tmp/failure/#{self.class.description.parameterize}/#{example.description.parameterize}.png", :full => true
    end
  end
end