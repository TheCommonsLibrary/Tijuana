class GetTogethersController < ApplicationController
  include ThemeModule

  MAX_NUMBER_OF_NATIONWIDE_RESULTS = 200
  MAX_NUMBER_OF_SEARCH_RESULTS = 99

  caches_action :show,
                :expires_in => 5.minutes,
                :if => proc { request.format && request.format.json?},
                :cache_path => :show_get_together_cache

  def index
    @current_get_togethers = GetTogether.occurs_after(Time.now)
    @past_get_togethers = GetTogether.occurs_before(Time.now)
  end

  def show
    get_get_together
    respond_to do |format|
      format.html {
        render layout: layout_path(@get_together.theme.name)
      }
      format.json {
        @search_origin = Postcode.find_by_number(params[:origin_postcode]) if params[:origin_postcode]
        @search_origin = [params[:latitude].to_f, params[:longitude].to_f] if params[:latitude] && params[:longitude]
        @search_radius = search_radius
        if @search_origin
          @events = @get_together.get_sorted_local_events(@search_origin, @search_radius, search_limit, :slugs, :host, :attendees)
        else
          if params[:origin_postcode].blank?
            @events = get_nationwide_events(@get_together)
            if @events.length > MAX_NUMBER_OF_NATIONWIDE_RESULTS
              @events = []
            end
          else
            @events = []
          end
        end
        render
      }
    end
  rescue ActiveRecord::RecordNotFound
    resource_not_found
  end

  private

  def get_nationwide_events(get_together)
    community_events = get_confirmed_events(get_together)
    managed_events = get_together.managed_get_together.present? ? get_confirmed_events(get_together.managed_get_together) : []
    community_events + managed_events
  end

  def get_confirmed_events(get_together)
    get_together.events.confirmed
          .includes(:slugs, :host)
          .with_number_of_attendees
          .limit(MAX_NUMBER_OF_NATIONWIDE_RESULTS+1)
  end

  def search_radius
    params[:search_radius].try(:to_i) || get_get_together.search_radius
  end

  def search_limit
    params[:limit].try(:to_i) || MAX_NUMBER_OF_SEARCH_RESULTS
  end

  def get_get_together
    @get_together ||= GetTogether.find(params[:id])
  end

  def show_get_together_cache_url
    if params[:origin_postcode]
      "#{get_together_url(params[:id])}-#{params[:origin_postcode]}-#{search_radius}km"
    elsif params[:latitude] && params[:longitude]
      "#{get_together_url(params[:id])}-#{rounded_01(params[:latitude])}-#{rounded_01(params[:longitude])}-#{search_radius}km"
    else
      get_together_url(params[:id])
    end
  end

  # corresponds to approx 0.5km granularity
  def rounded_01(n)
    n.to_f.round(2)
  end
end

