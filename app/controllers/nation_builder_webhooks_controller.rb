class NationBuilderWebhooksController < ApplicationController
  skip_before_filter :verify_authenticity_token
  before_filter :ensure_valid_nationbuilder_token
  respond_to :json

  def person_changed
    service.sync! params
    head :ok
  end

  private

  def ensure_valid_nationbuilder_token
    if params[:webhooks_token] != NATION_BUILDER[:webhooks_token]
      render text: 'invalid token', status: 403 
    end
  end
  
  def service
    @service ||= NationBuilder::SyncUserFromNbToTjService.new
  end
end
