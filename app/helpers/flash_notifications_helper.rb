module FlashNotificationsHelper

  KEY_MAP = {'notice' => :success, 'alert' => :error, 'warning' => :warning, 'success' => :success, 'error' => :error}

  def flash_notifications
    flash.inject({}) {|hash, vals|
      mapped_key = KEY_MAP[vals[0]]
      hash[mapped_key] = vals[1] unless mapped_key.nil?
      hash
    }
  end

  def gritter_error_message(message)
    gritter_message(:error, message)
  end

  def gritter_success_message(message)
    gritter_message(:success, message)
  end

  private 

  def gritter_message(key, message)
    add_gritter(message, :image => asset_path("common/lib/gritter/#{key}.png"), :sticky => true, :title=> key.to_s.capitalize)
  end

end
