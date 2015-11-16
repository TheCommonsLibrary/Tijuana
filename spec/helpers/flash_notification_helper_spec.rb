require File.expand_path(File.dirname(__FILE__) + "../../spec_helper")

describe FlashNotificationsHelper do

  it "should not return non notifications" do
    flash[:not_a_notification] = 'something else'
    helper.flash_notifications.should be_empty
  end

  KEY_MAP = {:notice => :success, :alert => :error, :warning => :warning, :success => :success, :error => :error}

  KEY_MAP.each do |key, mapped_key|
    it "maps key :#{key} to :#{mapped_key}" do
      value = "a value for #{key}"
      flash[key] = value
      helper.flash_notifications.size.should == 1
      helper.flash_notifications[mapped_key].should == value
    end
  end

end
