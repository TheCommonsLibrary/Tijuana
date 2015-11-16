class UsersController < ApplicationController
  before_filter :set_access_control_headers
  include PagePathModule

  def update
    begin
      authenticate_user!
      current_user.update_attributes!(user_params)
      respond_to do |format|
        format.html { render :text => "Ok", :layout => false }
        format.json { render :json => {"response" => "success"}, :layout => false }
      end
    rescue
      render :text => current_user.errors.to_json, :layout => false, :status => 400
    end
  end

  def address
    if !params[:drill_down_search_result_id].blank?
      response = address_service.lookup_address_using_search_result_id(params[:drill_down_search_result_id])
    else
      response = address_service.lookup_address_using_partial_address(params[:initial_address_query])
    end
    render json: response
  end

  def lookup
    email = (params[:email] || "").strip
    if valid_email_format?(email)
      @user_details_requirements = find_user_details_requirements
      @user = identify_user(email)
      if @user.new_record?
        if @user_details_requirements.required_user_details.values.all? { |v| v == :hidden }
          @msg = "It appears you are visiting for the first time. Welcome!"
        else
          @msg = "It appears you are visiting for the first time. Welcome! To take action, please enter your details below."
        end
      else
        @msg = "Thanks for entering your email."
        @user.clear_attributes(@user_details_requirements.user_details_that_are(:refresh))
      end
    else
      @msg = email.blank? ? "Please enter your email address." : "This is not a valid email address."
    end

    render json: {
      message: @msg,
      user: needed_attributes_hash(@user_details_requirements, @user),
      address_required: !!donation_requires_address?,
      show_subscribe: @user.present? && (@user.new_record? || !@user.is_member),
      quick_donate_card_info: view_context.quick_donate_card_info_if_quickdonate_cookie_for_user(@user)
    }
  end

  def find_user_details_requirements
    return Page.get_from_cache(params[:page_id]) if params[:page_id].present?
    return GetTogether.find(params[:get_together_id]) if params[:get_together_id].present?
  end

  def needed_attributes_hash(user_details_requirements, user)
    return unless user.present?
    make_address_fields_required(user_details_requirements) if donation_requires_address?
    attributes_needed = user_details_requirements.required_user_details.keys.inject({}){|memo, attr|
      memo[attr] = user_details_requirements.required_user_details[attr] != :hidden && user.send(attr).blank?
      memo
    }
    attributes_needed[:id] = user.id
    attributes_needed.merge(needs_more_details: user.needs_more_details_for_page(user_details_requirements))
  end

  #TODO move to donations
  def make_recurring
    begin
      donation_id = session[:action_id]
      donation = Donation.find(donation_id)
      donation.make_recurring!
      MakeRecurringReceiptEmail.new(donation).send!
      render json: {}
    rescue Exception => e
      ExceptionNotifier.notify_exception(e)
      render json: {}, status: 400
    end
  end

  def setup_quickdonate
    begin
      donation_id = get_and_clear_from_session(:action_id)
      donation = Donation.find(donation_id)
      donation.use_for_quickdonate
      view_context.enable_quickdonate_cookie_for(donation.user)
      render json: {}
    rescue
      render json: {}, status: 400
    end
  end

  def logout_quickdonate
    view_context.remove_quickdonate_cookie
    respond_to do |format|
      format.html do
        redirect_path = request.referer.blank? ? root_path : request.referer
        redirect_to redirect_path, notice: 'Successfully logged out.'
      end
      format.js { render nothing: true }
    end
  end

  def user_email_story
    response = {}
    token = TrackingTokenLookup.new(params[:t])
    if token.user && (story = token.user.message_on_content_module_id(params[:cm]))
      response[:story] = story
    end
    render json: response
  end

  def not_you
    return unless secure_user = User.find_by_id(cookies.signed[:user_id])
    [:user_track, :user_id].each{|cookie| cookies.delete(cookie, domain: :all) }
    page = Page.find(params[:page_id])
    UserActivityEvent.opted_out_of_one_click!(secure_user, page)
    render json: {url: path_to_url(friendly_path(page))}
  end

  private

  def make_address_fields_required(user_details_requirements)
    [:street_address, :postcode_number, :suburb, :country_iso].each do |field|
      user_details_requirements.required_user_details[field] = :required
    end
  end

  def donation_requires_address?
    (params[:donation_amount].try(:to_i) || 0) >= 250
  end

  def identify_user(email)
    User.find_by_email(email) || User.new
  end

  def get_and_clear_from_session(key)
    val = session[key]
    session.delete(key)
    val
  end

  def set_access_control_headers
    response.headers['Access-Control-Allow-Origin'] = '*'
    response.headers['Access-Control-Request-Method'] = 'GET'
  end

  def user_params
    (params[:user] || {}).slice(:first_name, :last_name, :email, :home_number, :mobile_number, :street_address, :suburb, :country_iso, :postcode_number)
  end

  def address_service
    ADDRESS_SERVICE
  end
end
