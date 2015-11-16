class PastCampaignModule < ContentModule
  MAX_PAST_ACTIONS = 10
  for i in (1..MAX_PAST_ACTIONS)
    option_fields "action#{i}", "action#{i}_link"
  end  
  
  def self.for_container?(layout_container)
    layout_container == :main_content
  end
end
