module DeviceSizeHelper
  def mobile_portrait_size
    [375, 667]
  end
  
  def mobile_landscape_size
    [667, 375]
  end
  
  def tablet_landscape_size
    [1024, 768]
  end
  
  def tablet_portrait_size
    [800, 1024]
  end
  
  def large_desktop_size
    [1920, 1024]
  end
end

RSpec.configuration.include DeviceSizeHelper, :type => :feature 