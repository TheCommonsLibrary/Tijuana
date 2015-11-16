class AccordionModule < ContentModule
  validates :title, :presence => true
  def self.for_container?(layout_container)
    [:main_content, :sidebar, :aside_content].include?(layout_container)
  end

  def handles_extended_validation?
    true
  end
end