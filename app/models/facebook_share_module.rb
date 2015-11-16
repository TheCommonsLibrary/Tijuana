class FacebookShareModule < ContentModule
  option_fields :link, :button_text, :query

  after_initialize :defaults

  def self.for_container?(layout_container)
    [:main_content].include? layout_container
  end

  private

  def defaults
    self.button_text = "Share on Facebook" unless self.button_text
  end

end
