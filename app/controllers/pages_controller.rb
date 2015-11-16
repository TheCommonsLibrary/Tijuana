require 'will_paginate/array'
require 'stats/transparency_stats'

class PagesController < ApplicationController
  include ThemeModule
  include PagePathModule
  helper RemarketingHelper

  prepend_before_filter :identify_page # Prepend because this needs to run before the SSL check. This will not be apparent in development.

  before_filter :ensure_current_page_url, :only => [:show]
  before_filter :view_path_filter, :only => [:show, :take_action]

  protect_from_forgery :except => [:paypal_cancel, :paypal_completed, :make_action]

  PAGE_SIZE = 5

  def show
    #featured toggled redirect from page when expirey reached
    if Setting.enabled?('expired_page_redirect') && @page_sequence.reached_expiry?
      return redirect_when_expired
    end
    # setup no cache headers. Shouldn't be needed but varnish seems to be acting up on heroku
    response.headers["Cache-Control"] = "no-cache, no-store, max-age=0, must-revalidate"
    response.headers["Pragma"] = "no-cache"

    utm_params = params.slice(:utm_campaign, :utm_source, :utm_medium)
    @token = params[:t] || generate_from_utm_params!
    token = TrackingTokenLookup.new(@token)
    @email = token.email
    @http_referrer = request.referrer
    @token_user = token.user
    @acquisition_source = token.acquisition_source
    @clear_user_details_form = true
    @secure_user = secure_user
    @user = User.new

    ExceptionNotifier.rescue_and_mail_tech do
      track_analytics_dimension 'Landing Page', 2, @page_sequence.landing_page.name
      track_analytics_dimension 'Campaign', 3, @page_sequence.campaign ? @page_sequence.campaign.name : 'None'
      track_analytics_dimension 'Primary Ask', 4, @page_sequence.landing_page.has_an_ask? ? @page_sequence.landing_page.ask_module.class.name.titleize : 'None'
    end
    
    log_pre_action_data
    @page.all_content_modules.each {|cm| set_module_properties(cm)}

    if @page.no_wrapper
      render :layout => "bare"
    else
      render :layout => theme_layout_path
    end
  end

  def make_action
    take_action 
  end

  def take_action
    return redirect_to friendly_path(@page) unless request.post?
    return redirect_to root_path unless identify_ask
    return redirect_to friendly_path(@page) unless identify_user

    result = take_action_common
    if result == :success
      set_identify_user_cookie
      redirect_to next_page
    else
      render :action => :show, :layout => theme_layout_path
    end
  end

  # This is used for non-javascript paypal donations
  def paypal
    render text: "This is not a donation page", status: 400 unless @page.has_a_donation?
  end

  def paypal_completed
    redirect_to friendly_path(@page.next || @page)
  end

  def paypal_cancel
    redirect_to friendly_path(@page)
  end

  private

  def take_action_common
    extract_tracking_token
    update_ask_attributes_and_validate

    if (use_stored_user_details? || onboard_user_and_save_valid_details) && take_action_on_module
      log_post_action_data
      log_user_activity_event(@ask.post_action_user_activity_event)
      ThankyouEmail.new(@page, @user, @ask).send! if @page.send_thankyou_email?
      session[:action_id] = @ask.action_id.to_s if @ask.respond_to? :action_id
      amount, frequency = nil, nil
      @ask.if_trackable_donation_made do |amount_in_cents, user, donation|
        amount, frequency = donation.amount_in_dollars, donation.frequency
        track_with_user :money, amount_in_cents, user, donation
      end
      Mautic.new.post_submission(@ask.mautic_id, @user.email, amount, frequency, cookies[:mtc_id]) if AppConstants.mautic_auth.present?
      track_with_user :actions, 1, @user, nil
      return :success
    else
      @http_referrer = params[:http_referrer]
      return :failure
    end
  rescue DuplicateActionTakenError
    return :success
#TODO - restrict to user model only
  rescue ActiveRecord::RecordNotUnique
    return :success
  end

  def extract_tracking_token
    @trackingTokenLookup = TrackingTokenLookup.new(params['t'])
    @token_user = @trackingTokenLookup.user
    @email = @trackingTokenLookup.email
    @acquisition_source = @trackingTokenLookup.acquisition_source
  end

  def update_ask_attributes_and_validate
    @ask.set_user_and_page(@user, @page)
    # if user details are invalid, we still want to display errors for the ask fields
    @ask.update_action_attributes_and_validate(params)
  end

  def onboard_user_and_save_valid_details
    return true if @secure_user
    valid = false
    subscribed = @user.did_subscribe_during? do
      valid = @user.validate_and_always_save_email(@page.required_user_details, params[:user], @page, @ask, @email, @acquisition_source)
    end
    if subscribed
      UserMailer.welcome_to_getup(@user) if !@page.quarantined? && !@page.welcome_email_disabled?
      @user.quarantine!(email: @email, page: @page) if @page.quarantined?
    end
    valid
  end

  def next_page
    token_param = params[:t] ? {t: params[:t]} : {}
    next_page_path(@page, token_param)
  end

  def next_page_full_url
    token_param = params[:t] ? {t: params[:t]} : {}
    next_page_url(@page, token_param)
  end
  helper_method :next_page_full_url

  def log_pre_action_data
    @asks = @page.content_modules.select {|cm| cm.is_ask? == true}
    @asks.each {|ask| warehouse_data ask.pre_action_data_for_logger({user: @token_user})}
  end

  def log_post_action_data
    warehouse_data @ask.post_action_data_for_logger
  end

  def take_action_on_module
    shared_connection = create_shared_connection
    remote_ip = request.local? ? '127.0.0.1' : request.remote_ip
    @ask.take_action(@user, @page, @email, params,
        {ip: remote_ip, shared_connection: shared_connection, acquisition_source: @acquisition_source})
  end

  def create_shared_connection
    shared_connection = nil
    if @trackingTokenLookup && @trackingTokenLookup.valid?
      shared_connection = SharedConnections.new(
        originator: @trackingTokenLookup.user,
        action_taker: @user,
        http_referrer: params ? (params[:http_referrer] || "").slice(0,255) : nil
      )
    end
    shared_connection
  end

  def campaign_from_cloaked_domain
    campaign_name = AppConstants.cloaked_domains.constants_hash["#{request.host}"]['campaign']
    Campaign.get_from_cache(campaign_name)
  end

  def identify_campaign(campaign_name=nil)
    if CloakedDomain.find(request.host) && campaign_name.blank?
      campaign_from_cloaked_domain
    elsif !campaign_name.blank? && !CloakedDomain.find(request.host)
      Campaign.get_from_cache(campaign_name)
    else
      nil
    end
  end

  def identify_page_sequence(campaign, page_sequence_id)
    if campaign
      PageSequence.get_from_cache(campaign, page_sequence_id)
    else
      PageSequence.static.find(page_sequence_id)
    end
  end

  #NOTE: params[:campaign_id] is campaign.name
  def identify_page
    @campaign = identify_campaign(params[:campaign_id])

    @page_sequence = identify_page_sequence(@campaign, params[:page_sequence_id])
    if params[:id].blank?
      @page = @page_sequence.pages.first
    else
      @page = page_finder(@page_sequence, params[:id])
    end
    @valid_main_content_modules = @page.valid_main_content_modules
    page_no = params[:page].blank? ? nil : params[:page].gsub(/[^0-9]/, '')
    page_no = nil if page_no.blank?
    @valid_main_content_modules = @valid_main_content_modules.paginate(per_page: PAGE_SIZE, page: page_no, order: 'created_at DESC') if @page.paginate_main_content?
    @valid_aside_content_modules = @page.valid_aside_content_modules
  rescue ActiveRecord::RecordNotFound
    resource_not_found
  end

  def page_finder(page_sequence, page_slug)
    return Page.find(page_slug) if page_slug.to_i > 0

    FriendlyId::Slug
      .where(slug: page_slug, sluggable_type: "Page")
      .joins("JOIN pages on friendly_id_slugs.sluggable_id = pages.id AND pages.deleted_at IS NULL")
      .where(pages: {page_sequence_id: page_sequence.id})
      .first
      .sluggable
  rescue NoMethodError
    raise ActiveRecord::RecordNotFound, "Couldn't find Page with slug=#{page_slug}"
  end

  def ensure_current_page_url
    current = true
    current = false if params[:campaign_id] && params[:campaign_id] != @campaign.friendly_id
    current = false if params[:page_sequence_id] && params[:page_sequence_id] != @page_sequence.friendly_id
    current = false if params[:id] && params[:id] != @page.friendly_id
    unless current
      preserved_params = params[:t].nil? ? {} : {:t => params[:t]}
      redirect_to friendly_path(@page, preserved_params), :status => :moved_permanently
    end
  end

  def identify_ask
    # The ask which is transiently updated with the form values must be the same instance as the one later used to re-render the form.
    # An apparent bug in activerecord's has_many :through associations returns different instances across
    # multiple calls to @page.content_modules.
    # Possibly related to https://rails.lighthouseapp.com/projects/8994/tickets/4642
    rendered_modules = @page.sidebar_content_modules + @page.main_content_modules
    if @ask = rendered_modules.find { |cm| cm.id == params[:module_id].to_i }
      set_module_properties(@ask)
    end
  end

  def set_module_properties(content_module)
    content_module.session = session
    content_module.cookies = cookies
    content_module.flash = flash
    content_module.params = params
    content_module.current_user = current_user
    content_module.user_notifier = Proc.new{|level, title, message| notify_user(level, title, message)}
    content_module.email_notifier = Proc.new{|exception, options| ExceptionNotifier::Notifier.exception_notification(request.env, exception, options).deliver}
  end

  def identify_user
    if @ask.identifies_user?
      @user = @ask.identified_user
    elsif params[:use_cookie] && (@secure_user = secure_user)
      @user = @secure_user
    else
      return nil if params[:user].blank? || params[:user][:email].blank?
      addr = params[:user][:email].strip
      @user = User.find_by_email(addr)
      @user ||= User.new(:email => params[:user][:email])
    end
  end

  def use_stored_user_details?
    @ask.identifies_user?
  end

  def page_contains_secure_module?
    @page.has_a_donation?
  end

  def view_path_filter
    enable_theme_view_overrides(theme_name)
  end

  def redirect_when_expired
    if @page_sequence.expired_redirect_page_sequence.try(:landing_page)
      return redirect_to friendly_path(@page_sequence.expired_redirect_page_sequence.landing_page)
    elsif offsite_uri = Setting["website_pillar_uri"]
      pillar_uri = @page_sequence.campaign.try(:pillar) && @page_sequence.campaign.pillar.downcase.gsub(/\W/, '-')
      offsite_uri += "/#{pillar_uri}" if pillar_uri
      return redirect_to offsite_uri
    end
  end

  protected

  def theme_name
    @page_sequence.theme.nil? ? @campaign.theme.name.downcase : @page_sequence.theme.name.downcase
  end

  def theme_layout_path
    layout_path(theme_name)
  end

  def set_identify_user_cookie(user = @user)
    cookies.permanent.signed[:user_id] = {value: user.id, domain: :all}
    cookies.permanent[:user_track] = {value: user.id, domain: :all}
  end

  def secure_user
    return nil if @page.tag_list.include?('disable-one-click')

    if (cookie_user = User.find_by_id(cookies.signed[:user_id]))
      return cookie_user if cookie_user.has_required_details_for(@page)
    end

    if @token_user &&
        @page.page_sequence.landing_page.tag_list.include?('token-recognition') &&
        @token_user.has_required_details_for(@page)
      set_identify_user_cookie(@token_user)
      return @token_user
    end
  end

  def generate_from_utm_params!
    source_fields = { generated: true }
    {name: 'campaign', medium: 'medium', source: 'source'}.each{|key, param|
      sanitised_value = params["utm_#{param}"].try(:gsub, /[^a-zA-Z0-9\-_]/, '')
      return unless sanitised_value.present?
      source_fields[key] = sanitised_value
    }
    source = AcquisitionSource.find_or_create_by(source_fields)
    if source.valid?
      EmailTrackingToken.encode_with_source(source.id)
    end
  end
end
