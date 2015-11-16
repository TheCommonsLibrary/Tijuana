module PagesHelper
  def get_page(page)
    get :show, { 
        campaign_id: page.page_sequence.campaign.friendly_id,
        page_sequence_id: page.page_sequence.friendly_id,
        id: page.name
    }
  end
end

RSpec.configuration.include PagesHelper
