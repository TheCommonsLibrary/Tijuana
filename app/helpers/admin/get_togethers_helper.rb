module Admin::GetTogethersHelper
  def public_event_url(path)
    path.gsub(/^https:\/\//, 'http://')
  end

  def capacity_enabled_attributes(get_together)
    if get_together.new_record? || get_together.capacity_enabled?
      {:checked => 'checked'}
    else
      {}
    end
  end
end
