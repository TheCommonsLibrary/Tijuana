class HtmlModule < ContentModule
  def self.for_container?(layout_container)
    [:header_content, :main_content, :sidebar, :aside_content].include?(layout_container)
  end

  def handles_extended_validation?
    true
  end
end