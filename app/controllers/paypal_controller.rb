class PaypalController < ApplicationController

  skip_before_filter :verify_authenticity_token

  def ipn
    PaypalPaymentNotificationHandler.new(params, request.raw_post).verify_and_handle_ipn

    user_id = user_id_from_params(params)
    token = token_from_params(params)
    token_user_id = token_user_id_from_params(params)

    warehouse_data(user_id: user_id, token_user_id: token_user_id, token: token)

    render :nothing => true
  end

  private
  def user_id_from_params(params)
    email = params["payer_email"]
    user = User.find_by_email(email) unless email.blank?
    user.nil? ? '' : user.id
  end

  def token_from_params(params)
    _,_,token = params['id'].split('-') unless params['id'].blank?
    token.nil? ? '' : token
  end

  def token_user_id_from_params(params)
    _,_,token = params['id'].split('-') unless params['id'].blank?
    tokenLookup = TrackingTokenLookup.new(token)
    tokenLookup.user.nil? ? '' : tokenLookup.user.id
  end

end
