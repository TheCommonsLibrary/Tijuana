module AnalyticsHelper
  include ActionView::Helpers::JavaScriptHelper
  
  def track_analytics_event(category, action, label, value)
    track_analytics :analytics_events, [category, action, label, value]
  end
  
  def analytics_events_js
    safely_map_to_js :analytics_events do |category, action, label, value|
      "ga('send', 'event', '#{category}', '#{action}', '#{label}', #{value});"
    end
  end
  
  def track_analytics_dimension(name, index, value)
    track_analytics :analytics_dimensions, [name, index, value]
  end
  
  def analytics_dimensions_js
    safely_map_to_js :analytics_dimensions do |name, index, value|
      "ga('set', 'dimension#{index}', '#{escape_javascript value}'); // #{name}"
    end
  end

  def target_ip?(remote_ip)
    govt_ips = AppConstants.govt_ips.try(:split, ',')
    govt_ips.present? && govt_ips.include?(remote_ip)
  end
  
private

  
  def track_analytics(key, values)
    return if flash.nil? # for example in api controller
    flash[key] ||= []
    flash[key] << values
  end
  
  def safely_map_to_js(key)
    js = nil
    ExceptionNotifier.rescue_and_mail_tech do
      arr = flash[key]
      flash.discard(key)
      if arr
        js = arr.map { |e| yield(*e) }.join("\n").html_safe
      end
    end
    js
  end
end
