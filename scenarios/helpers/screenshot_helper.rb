module ScreenshotHelper
  def responsive_screenshot(name)
    # :large_desktop_size does not trigger the large size media queries?? Leaving out for now...
    [:mobile_portrait_size, :mobile_landscape_size, :tablet_landscape_size, :tablet_portrait_size].each do |size|
      resize_window *send(size)
      page.save_screenshot "tmp/#{self.class.description.parameterize}/#{example.description.parameterize}/#{name.parameterize}-#{size}.png"
    end
  end
end

RSpec.configure do |config|
  config.include ScreenshotHelper, :type => :feature
  
  config.before :each do
    FileUtils.rm_rf Dir.glob("tmp/screenshots/#{self.class.description.parameterize}/#{example.description.parameterize}/*")
  end
end