class ApplicationController < ActionController::Base
  protect_from_forgery

  include SessionsHelper
  include EmailFormatHelper
  include ApplicationControllerHelper
  include VanityHelper
  include AnalyticsHelper
  
  use_vanity
  
  before_filter :set_return_to_path

  rescue_from CanCan::AccessDenied, :with => :access_denied
  rescue_from ActionView::MissingTemplate, :with => :resource_not_found

  protected

  def set_return_to_path
    session[:return_to] = params[:return_to] if params[:return_to]
  end

  def after_sign_in_path_for(resource_or_scope)
    case resource_or_scope
    when :user, User
      store_location = session[:return_to]
      clear_stored_location
      #Note that the you can set the redirect_to in a user link using :user_return_to
      #when you create the link.
      (store_location.nil?) ? "/dashboard" : store_location.to_s
      else
        super
    end
  end

  def access_denied
    if anyone_signed_in?
      warden.custom_failure!
      render :file => "public/401", :formats => [:html], :status => 401
    else
      deny_access
    end
  end

  # type in [:error, :warning, :success]
  def notify_user(icon, title, message)
    flash[:notify_user] = {:image => icon, :title => title, :message => message }
  end

  # Append extra info to be added to LogRage logging
  def append_info_to_payload(payload)
    super
    ExceptionNotifier.rescue_and_mail_tech do
      set_payload_safe(payload, :agent, request.env['HTTP_USER_AGENT'])
      set_payload_safe(payload, :referrer, request.env['HTTP_REFERER'])
      payload[:source] = request.remote_ip
      payload[:facebook] = !!request.env['HTTP_REFERER'].try(:match, /facebook/i)
      payload[:youtube] = !!request.env['HTTP_REFERER'].try(:match, /youtube/i)
      payload[:twitter] = !!request.env['HTTP_REFERER'].try(:match, /twitter/i)
      cookies.permanent[:device_id] = request.uuid unless cookies[:device_id]
      set_payload_safe(payload, :request_id, request.uuid, 32)
      set_payload_safe(payload, :device_id, cookies[:device_id], 32)
      set_payload_safe(payload, :user_cookie, cookies[:user_track].to_s, 32)
      payload[:timestamp] = Time.now.to_s
      payload[:events] = @events_to_log
      [:user, :campaign, :page, :email, :token_user].each do |to_record|
        payload[:"#{to_record}_id"] = instance_variable_get("@#{to_record}").try(:id)
      end
      payload[:token] = request.params['t']
      payload[:query] = request.query_parameters
      [:page_sequence, :ask, :acquisition_source].each do |to_record|
        payload[:"#{to_record}_id"] = instance_variable_get("@#{to_record}").try(:id)
      end
      payload.merge!(@warehouse_data) if @warehouse_data
    end
  end

  # Store data to be logged to data warehouse
  def warehouse_data(hash)
    @warehouse_data ||= {}
    @warehouse_data.merge!(hash)
  end

  # Store basic data about a UserActivityEvent in @events_to_log so that it can
  # be used later as part of enhanced logging.
  # See ApplicationController.append_info_to_payload
  def log_user_activity_event(event)
    ExceptionNotifier.rescue_and_mail_tech do
      return unless event
      @events_to_log ||= []
      @events_to_log.push(event.attributes.reject{|k,v|
        !["id", "activity", "source", "content_module_type", "acquisition_source_id"].include?(k)
      })
    end
  end

  def authenticate_api_token!
    token = request.headers["Auth-Token"]
    unless token.present? && token == Setting['api_token']
      head :unauthorized
    end
  end

  private

  def resource_not_found
    raise if Rails.env.development? 

    respond_to do |format|
      format.json { render :json => {"Not found" => "Entity not found"}, :layout => false, :status => 404 }
      format.any  { render :file => "#{Rails.root}/public/404", :formats => [:html], :status => "404", :layout => false }
    end
  end
end
