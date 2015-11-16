module BrowserHelper
  def resize_window(width, height)
    case Capybara.current_driver
    when :poltergeist_debug
      page.driver.resize width, height
    when :selenium
      window = Capybara.current_session.driver.browser.manage.window
      window.resize_to(width, height)
    else
      raise "don't know how to resize this browser yet!"
    end
  end
end

RSpec.configuration.include BrowserHelper, :type => :feature