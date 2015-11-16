module Admin::DonationsHelper
  def selected_campaign_id
    return nil if @donation.new_record? || @donation.page_id == 1
    if @donation.page.page_sequence.campaign
      @donation.page.page_sequence.campaign.id
    else
      nil
    end
  end
end
