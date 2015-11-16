module EmailTrackingFieldHelper

  def email_tracking_field
    if token = (params[:t] || @token)
      hidden_field_tag(:t, token, id: nil)
    end
  end

  def secure_token_field
    hidden_field_tag(:secure_token, params[:secure_token], id: nil) unless params[:secure_token].blank?
  end
end
