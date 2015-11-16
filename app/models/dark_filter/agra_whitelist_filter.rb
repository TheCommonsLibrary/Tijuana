class DarkFilter::AgraWhitelistFilter < DarkFilter::DarkFilter

  include DarkFilter::WhitelistFilterConcern

  # Add a member to this experiment if they have been subscribed from community
  # run and have had community run categories set that match at least one
  # campaign in Tijuana.  Add a campaign whitelist for any campaign with tags
  # that match the categories.
  def add_member_to_experiment(member, subscription_data={})
    campaigns = extract_campaigns_from_community_run_categories(subscription_data)
    return if campaigns.empty?
    experiment = super
    if experiment
      campaigns.each do |campaign|
        campaign_white_lists.create!(user: member, joining_campaign: campaign, campaign: campaign) 
      end
    end
    experiment
  end

  # Add a member to this control if they have been subscribed from community
  # run and have had community run categories set that match at least one
  # campaign in Tijuana.
  def add_member_to_control(member, subscription_data={})
    return if extract_campaigns_from_community_run_categories(subscription_data).empty?
    super
  end

  def agra_only?
    true
  end

  protected

  def extract_campaigns_from_community_run_categories(subscription_data)
    categories = subscription_data[:community_run_categories] || []
    Campaign.tagged_with(categories, any: true)
  end
end
