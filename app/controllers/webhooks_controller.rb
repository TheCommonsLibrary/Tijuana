class WebhooksController < ApplicationController
  skip_before_filter :verify_authenticity_token
  before_filter :ensure_valid_webhook_token
  respond_to :json

  def call_outcome
    call_outcome = CallOutcomeService.new.process params
    CallOutcome.create! call_outcome
    head :ok
  end

  private

  def ensure_valid_webhook_token
    if params[:token] != AppConstants.webhook_token
      render text: 'invalid token', status: 403
    end
  end
end
