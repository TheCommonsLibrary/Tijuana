class ScorecardsController < ApplicationController
  layout false

  # params if user gives location permission: latlng=40.714224,-73.961452
  # no params if no location permission
  # this method will be requested from phonegap app
  def index
    location = to_location(params["latlng"])
    render :locals => { scorecard: scorecard_name(location) }
  end

  # use this method for development, it has a layout and includes libraries etc
  def layout_for_dev
    render :action => :index, :locals => { scorecard: "nsw_scorecard" }, :layout => 'election_app'
  end

  def national
    render :action=>:index, :locals => { scorecard: scorecard_name(nil) }, :layout => 'election_app'
  end

private

  def scorecard_name(location=nil)
    if location.present?
      polling_booth =  PollingBooth.closest(origin: location.values).first
      "#{polling_booth.postcode.state.downcase}_scorecard"
    else
      "nationwide_scorecard"
    end
  end

  def to_location(latlng)
    if params["latlng"].present?
      array = latlng.split(',')
      { lat: array[0].to_f, lng: array[1].to_f }
    else
      nil
    end
  end
end
