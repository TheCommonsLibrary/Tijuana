class PollingBoothsController < ApplicationController

  MAX_NUMBER_OF_NATIONWIDE_RESULTS = 200
  MAX_NUMBER_OF_SEARCH_RESULTS = 99
  DEFAULT_SEARCH_RADIUS = 5000
  
  skip_before_filter :verify_authenticity_token

  def index
    if request.request_method == "OPTIONS"
      headers['Access-Control-Allow-Origin'] =  '*'
      headers['Access-Control-Request-Method'] = '*'
      return head(:ok)
    end
    respond_to do |format|
      format.json {
        @search_origin = Postcode.find_by_number(params[:origin_postcode]) if params[:origin_postcode]
        @search_origin = [params[:latitude].to_f, params[:longitude].to_f] if params[:latitude] && params[:longitude]
        @search_radius = search_radius
        booths = params[:pre] ? PrePollingBooth : PollingBooth
        if @search_origin
          @polling_booths = booths
            .within(@search_radius, :origin => @search_origin)
            .order('distance ASC')
            .limit(search_limit)
        else
          @polling_booths = booths.limit(MAX_NUMBER_OF_NATIONWIDE_RESULTS+1)
          if @polling_booths.length > MAX_NUMBER_OF_NATIONWIDE_RESULTS
            @polling_booths = []
          end
        end
        render :polling_booths
      }
    end
  end

private

  def search_radius
    params[:search_radius].try(:to_i) || DEFAULT_SEARCH_RADIUS
  end

  def search_limit
    params[:limit].try(:to_i) || MAX_NUMBER_OF_SEARCH_RESULTS
  end

end
