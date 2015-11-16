class DarkFilter::CampaignWhitelistFilter < DarkFilter::DarkFilter

  include DarkFilter::WhitelistFilterConcern

  include SerializedOptions
  option_fields :whitelist_related_campaigns

  # Add a member to this experiment and add a white list entry for the joining
  # campaign and any other campaigns specified
  def add_member_to_experiment(member, subscription_data={})
    campaign = extract_campaign_from_subscription_data(subscription_data)
    return unless campaign && new_member?(member)
    experiment = super
    # Member must be in the experiment and must have joined on a campaign
    if experiment
      campaigns_to_white_list = [campaign]
      if whitelist_related_campaigns
        campaigns_to_white_list = campaigns_to_white_list.concat(campaign.find_related_tags)
      end
      campaigns_to_white_list.each do |white_list_campaign|
        campaign_white_lists.create!(user: member, joining_campaign: campaign, campaign: white_list_campaign) 
      end
    end
    experiment
  end

  # Add a member to the control only if we can extract the campaign (so that
  # the control members are selected the same way as the experiment)
  def add_member_to_control(member, subscription_data={})
    return unless extract_campaign_from_subscription_data(subscription_data) && new_member?(member)
    super
  end

  protected

  def extract_campaign_from_subscription_data(subscription_data)
    subscription_data[:email].try(:blast).try(:push).try(:campaign) ||
    subscription_data[:page].try(:page_sequence).try(:campaign)
  end

  def new_member?(member)
    member.created_at.nil? || member.created_at > 4.hours.ago # allow time for delayed queue
  end
end
