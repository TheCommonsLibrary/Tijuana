class OzvoteController < ApplicationController
  layout "election_app"

  def index
  end

  def vote
    electorate_slug =params[:electorate].humanize.gsub(/\b([a-z])/) { $1.capitalize }
    @electorate = Electorate.find_by_name_and_jurisdiction_id(electorate_slug, 9)
    @embed = params[:embed] ? "embedded-body" : ""
    @senate_only = !!params[:senate]
    render layout: 'vote'
  end

end
