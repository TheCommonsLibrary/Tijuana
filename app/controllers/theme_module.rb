module ThemeModule

  # use: render :action => :myview, :layout => layout_path(theme_name)
  def layout_path(theme_name)
    if theme_name.blank? || theme_name.downcase == 'application'
      'application'
    else
      "themes/#{theme_name.downcase}"
    end
  end

  def enable_theme_view_overrides(theme_name)
    prepend_view_path("app/views/themes/" + theme_name.downcase) unless theme_name.blank?
  end

end
