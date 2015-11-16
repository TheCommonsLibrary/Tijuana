class TestimonialController < ApplicationController
  def record_action
    testimonial_module = ContentModule.find(params[:module_id].to_i)
    user = User.find(cookies.signed[:user_id].to_i)
    page = Page.find(params[:page_id].to_i)
    tracking_token = TrackingTokenLookup.new(params[:t])
    email = tracking_token.email
    options = {app_id: params[:app_id], facebook_id: params[:facebook_id].to_i, testimonial_text: params[:testimonial_text]}
    
    testimonial_module.record_action(user, page, email, params, options)
    head :ok
  end
end
