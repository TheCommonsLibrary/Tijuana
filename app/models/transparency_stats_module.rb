class TransparencyStatsModule < ContentModule
  def self.for_container?(layout_container)
    [:main_content, :aside_content].include?(layout_container)
  end
end
