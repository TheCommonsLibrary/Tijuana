module SessionsHelper

  def deny_access
    store_location
    redirect_to new_user_session_path
  end

  def unauthorized_access
    render :file => "public/401", :formats => [:html], :status => 401
  end

  def anyone_signed_in?
    !current_user.nil?
  end

  private

  def store_location
    session[:return_to] = request.fullpath
  end

  def clear_stored_location
    session[:return_to] = nil
  end

  def user_ip
    request.env['HTTP_X_REAL_IP'] || request.env['REMOTE_ADDR'] || request.env['X_FORWARDED_FOR'] || request.remote_ip
  end

end
