class StandfirstModule < ContentModule
  def self.for_container?(layout_container)
    [:main_content].include?(layout_container)
  end
end