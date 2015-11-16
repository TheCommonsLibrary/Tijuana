class EventsController < ApplicationController
  include ThemeModule
  before_filter :authenticate_user!, :only => [:cancel, :index, :edit]
  before_filter :check_permissions, :only => [:edit, :update, :cancel]
  before_filter :check_permissions_message, :only => [:message_attendees]

  def show
    @event = Event.with_number_of_attendees.find(params[:id])
    @user = current_user || User.new
    @user_details_requirements = @event.get_together
    @clear_user_details_form = true
    render layout: get_together_theme
  rescue ActiveRecord::RecordNotFound
    resource_not_found
  end

  def edit
    event = Event.find(params[:id])
    @host = event.host
    @event = event
    render layout: get_together_theme
  end

  def update
    @event = Event.find(params[:id])
    notifier = UpdateNotifier.new(@event)
    if can?(:update_host, @event) && params[:host].present?
      @event.host = User.find_or_create_by_email(params[:host][:email])
      UserActivityEvent.registered_to_host! @event.host, @event if @event.host_id_changed?
    end
    if @event.update_attributes(params[:event])
      notifier.notify_attendees_if_important_update
      redirect_to event_path(@event), :notice => "Event has been updated."
    else
      flash[:error] = "Your event has not been updated. Please fix the errors below."
      @host = @event.host
      render :action => "edit", layout: get_together_theme
    end
  end

  def new
    if params[:get_together_id].blank? 
      redirect_to get_togethers_path
    else 
      @event = Event.new
      @event.get_together = GetTogether.find(params[:get_together_id])
      if can?(:manage, @event) 
        render layout: get_together_theme
      else
        unauthorized_access
      end
    end
  end

  def create
    @event = Event.new params[:event]
    @event.get_together = GetTogether.find(params[:get_together_id])
    @host = User.find_or_create_by_email(params[:host][:email])
    @event.host = @host
    if current_user && current_user.is_admin?
      @event.confirmed_at = Time.now
      @confirmation_code = nil
    end

    if @event.get_together.managed_get_together.present?
      managed_get_together = @event.get_together.managed_get_together
      if managed_get_together.confirmed_events_within(managed_get_together.exclusion_radius, :origin => [@event.address_latitude.to_f, @event.address_longitude.to_f]).present?
        raise "Can not create event within exclusion radius of events in managed get together #{@event.get_together.managed_get_together.id}"
      end
    end

    if @host.errors.blank? && @event.save
      if current_user && current_user.is_admin?
        UserActivityEvent.registered_to_host! @host, @event
      end
      @email = TrackingTokenLookup.new(params[:t]).email
      UserActivityEvent.registered_create_event_from_email! @host, @event, @email
      redirect_to event_path(@event.friendly_id), :notice => "Event has been created."
    else
      flash[:error] = "Your event has not been saved. Please fix the errors below."
      render :action => "new", :layout => get_together_theme
    end
  end

  def confirm
    event = Event.find_by_confirmation_code(params[:cd])
    if event && !params[:cd].blank?
      event.confirm!
      UserActivityEvent.registered_to_host! event.host, event
      redirect_to event_path(event.friendly_id), :notice => "Your event has been confirmed!"
    else
      redirect_to root_path
    end
  end

  def cancel
    event = Event.find(params[:id])
    event.cancel!
    redirect_to event_path(event.friendly_id), :notice => "Your event has been canceled!"
  end

  def attend
    begin
      token = TrackingTokenLookup.new(params[:t])
      @event = Event.with_number_of_attendees.find(params[:id])
      @user = User.find_or_initialize_by_email(params[:user][:email])
      @email = token.email
      @user_details_requirements = @event.get_together
      if @user.validate_and_always_save_email(@user_details_requirements.required_user_details, params[:user], nil, nil, nil, token.acquisition_source)
        @event.add_attendee!(@user)
        UserActivityEvent.registered_to_attend! @user, @event, @email, token.acquisition_source
        redirect_user_after_registering_attendance
      else
        render :action => :show, layout: get_together_theme
      end
    rescue UserAlreadyAttendingError
      redirect_user_who_is_already_attending
    rescue ActiveRecord::RecordNotUnique
      redirect_user_after_registering_attendance
    end
  end

  def cancel_attendance
    event = Event.with_number_of_attendees.find(params[:id])
    user = User.find_by_email(params[:user][:email])
    if event.cancel_attendance!(user, params[:user][:reason])
      @msg = "Your attendance to this event has been canceled."
    end
    redirect_to event_path(event.friendly_id), :notice => @msg
  end

  def message_attendees
    event = Event.find(params[:id])
    if event.message_attendees(params[:message])
      @msg = 'Your message is in the process of being sent.'
    end
    redirect_to event_path(event.friendly_id), :notice => @msg
  end

  private

  def check_permissions
    event = Event.find(params[:id])
    authorize! :manage, event
  end

  def check_permissions_message
    event = Event.find(params[:id])
    authorize! :email_attendees, event
  end

  def get_together_theme
    layout_path(@event.get_together.theme.name)
  end

  def redirect_user_after_registering_attendance
    unless @event.get_together.redirect_url.blank?
      redirect_to(@event.get_together.redirect_url)
    else
      flash[:notice] =
          "Thanks for attending this event! You will receive an email shortly with everything you need to know!"
      redirect_to event_path(@event.friendly_id)
    end
  end

  def redirect_user_who_is_already_attending
    if @event.get_together.redirect_url.blank?
      flash[:notice] = "You have already registered to attend this event."
      redirect_to event_path(@event.friendly_id)
    else
      redirect_to(@event.get_together.redirect_url)
    end
  end
end
