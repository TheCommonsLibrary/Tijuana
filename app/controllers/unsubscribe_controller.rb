class UnsubscribeController < ApplicationController

  before_filter :check_for_token

  def new
    @user = User.new
    @community_run = params[:cr]
  end

  def create
    return redirect_to unsubscribe_path if params[:user].blank?
    user_email = params[:user][:email]
    @user = identify_user(user_email)
    @community_run = params[:community_run]

    return user_not_found(user_email) unless @user
    event = nil
    if subscribe_to_low_volume?(params)
      event = @user.set_low_volume!(@email) unless @user.low_volume?
      @msg = "We will only send you the most important updates to GetUp campaigns."
    else
      if @community_run
        if @user.is_agra_member?
          event = @user.unsubscribe!(@email, true, params[:reason], unsubscribe_specifics(params))
        end
      else
        if @user.is_member?
          event = @user.unsubscribe!(@email, false, params[:reason], unsubscribe_specifics(params))
        end
      end
      @msg = "Your subscription has been successfully cancelled."
    end
    log_user_activity_event(event)
    render :action => "create"
  end

  private

  def user_not_found(user_email)
    @user = User.new(email: user_email)
    flash[:alert] = email_error(user_email)
    render :action =>"new"
  end

  def identify_user(user_email)
    user_email = user_email.strip unless user_email.blank?
    User.find_by_email(user_email)
  end

  def email_error(user_email)
    case
      when valid_email_format?(user_email)
        "The email provided doesn't seem to belong to any user."
      when user_email.blank?
        "Please enter your email address."
      else
        "This is not a valid email address."
    end
  end

  def unsubscribe_specifics(params)
    case params[:reason]
    when 'specific campaigns'
      serialize_campaigns(params[:specific_campaigns])
    when 'campaign or tactic'
      params[:reason_campaign_or_tactic_field]
    when 'other'
      params[:reason_other_field]
    else
      nil
    end
  end

  def serialize_campaigns(campaigns)
    campaigns && campaigns.keys.join(",")
  end

  def subscribe_to_low_volume?(params)
    AppConstants.low_volume_enabled && params[:commit] == 'Send me less email'
  end

  def check_for_token
    @token = params['t']
    token = TrackingTokenLookup.new(@token)
    @token_user = token.user
    @email = token.email
  end

end
