class RadiosController < ApplicationController

  def lookup
    postcode = Postcode.find_by_number(params[:postcode].to_i)

    if postcode.nil?
      @msg = "Please enter a valid postcode."
      @shows_now = []
      @shows_not_now = []

    else
      shows = RadioShow.find_radio_shows(postcode.latitude, postcode.longitude)

      @shows_now = shows[:now]
      @shows_not_now = shows[:not_now]

      if @shows_now.empty? && @shows_not_now.empty?
        @msg = "No shows in your location."
      elsif @shows_now.empty? && !@shows_not_now.empty?
        @msg = "No shows in your location at present. Shows at other times..."
      else
        @msg = "Radio shows in your location."
      end
    end

    respond_to do |format|
      format.html { render :layout => false }
    end

  end

end

