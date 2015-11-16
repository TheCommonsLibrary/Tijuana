class DashboardController < ApplicationController
  ITEMS_PER_PAGE = 12

  before_filter :authenticate_user!, except: [:update_card]

  def index
    @events = {
        :as_host => current_user.events_hosted.within_three_months.with_number_of_attendees.includes(:slugs, :host, :get_together => :slugs).paginate(:page => params[:page], :per_page => 50),
        :as_attendee => current_user.events_attended.within_a_month.includes(:slugs, :host, :get_together => :slugs).paginate(:page => params[:page], :per_page => 50)
    }

    @campaigns = Campaign.find_all_by_opt_out(true)

    @recurring_donations = current_user.donations.where("frequency != ? AND active = ?", 'one_off', true)
    @from_date = 1.month.ago.beginning_of_day
    @to_date = Time.now.end_of_day
    @transactions = current_user.transaction_history(:from => @from_date, :to => @to_date)
    @transactions = @transactions.paginate(:page => params[:page], :per_page => ITEMS_PER_PAGE)
    @user = current_user
    render :layout => "dashboard/dashboard"
  end

  def donation_history
    begin
      @from_date = Date.strptime(params[:from], '%d-%m-%Y')
      @to_date = Date.strptime(params[:to], '%d-%m-%Y')
    rescue
      head(400, :content=> "Please pick a date or enter date in format dd-mm-yyyy.")
      return
    end

  @transactions = current_user.transaction_history(:from => @from_date, :to => @to_date)
    respond_to do |format|
      format.html {
        @transactions = @transactions.paginate(:page => params[:page], :per_page => ITEMS_PER_PAGE)
        render :partial => 'transaction_list'
      }
      format.js {
        @transactions = @transactions.paginate(:page => params[:page], :per_page => ITEMS_PER_PAGE)
        render :partial => 'donation_history'
      }
    end
  end

  def update_card
    @recurring_donation = Donation.find(params[:id])
    resource_not_found if !@recurring_donation.can_update_anonymously?
  end

  def cancel_event_attendee
    user_email = params.try(:[], :user).try(:[], :email)
    event, attendee = find_hosts_event(user_email)
    if event && event.cancel_attendance!(attendee, nil)
      flash[:notice] = "#{attendee.email}'s attendance to this event has been canceled."
    else
      flash[:error] = "Sorry. An error occurred cancelling the attendance to this event."
    end
    redirect_to "#{dashboard_path}#events"
  end

  def find_hosts_event(user_email)
    if user_email
      attendee = User.find_by_email(user_email)
      event = current_user.events_hosted.find_by(id: params[:id])
    else
      attendee = current_user
      event = attendee.events_attended.find_by(id: params[:id])
    end
    rescue
      # intentionally left blank
    ensure
    return event, attendee
  end

end
