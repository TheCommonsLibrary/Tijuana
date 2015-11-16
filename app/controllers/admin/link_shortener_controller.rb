module Admin
  class LinkShortenerController < AdminController
    skip_authorize_resource
    skip_authorization_check

    def generate_shortened_url
      disabled_id = 0
      user_id = params[:user_id].to_i || disabled_id
      email_id = params[:email_id].to_i || disabled_id
      page_id = params[:page_id].to_i || disabled_id
      redirect_id = params[:redirect_id].to_i || disabled_id

      hashids = Hashids.new(AppConstants.link_shortener_salt)
      hash = hashids.encode(user_id,email_id,page_id,redirect_id)

      render text: "http://#{AppConstants.link_shortener_domain}/#{hash}", status: 200
    end
  end
end
