module UnsubscribeHelper
  def campaigns
    [
      "Trans-Pacific Partnership",
      "Asylum Seekers",
      "Save Our Forests",
      "Corporate Tax",
      "Budget",
      "Medicare",
      "Higher Education",
      "Coal Seam Gas",
      "Palmer Promises",
      "Climate Action",
      "Great Barrier Reef",
      "Newstart",
      "Renewable Energy",
      "Media (ABC/SBS)",
    ]
  end

  def specific_campaign_key(campaign_name)
    "specific_campaigns[#{campaign_name.parameterize.underscore}]"
  end
end
