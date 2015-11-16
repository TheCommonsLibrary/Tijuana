module WebHelper
  def click_links(*texts)
    texts.each { |s| click_link s }
  end
  
  def current_css_path
    path = page.send(:scopes)[1..-1].map { |e| "#" + e[:id] }.join(' ')
    path.present? ? path : 'body'
  end
  
  def click_ajax_button(text)
    click_button text
    wait_for_ajax
  end

  def ignore_js_errors
    yield
  rescue Capybara::Poltergeist::JavascriptError
  end
  
  def press_enter(element)
    enter_key = Capybara.current_driver.to_s =~ /poltergeist/ ? :Enter : :enter
    element.native.send_key enter_key
  end
  
  def dismiss_dialog
    page.driver.browser.switch_to.alert.accept if Capybara.current_driver == :selenium
  end

  def fill_in_autocomplete(locator, query)
    find_field(locator).native.send_keys(*query.chars)
  end

  def click_on_first_autocomplete_item
    find('.ui-autocomplete').find('li:first-child').find('td:first-child').click
  end
end
RSpec.configuration.include WebHelper, :type => :feature
