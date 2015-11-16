require 'will_paginate/array'

class Admin::GetTogethersController < Admin::AdminController
  crud_actions_for GetTogether, :parent => Campaign, :redirects => {
      :create => lambda { admin_campaign_path(@campaign) },
      :update => lambda { admin_campaign_path(@campaign) },
      :destroy => lambda { admin_campaign_path(@campaign) }
  }

  PAGE_SIZE = 10

  def show
    query = params[:query]
    if query
      if /^(unconfirmed|canceled|full|open|ended)$/.match(params[:query].downcase)
        @events = @get_together.events.with_number_of_attendees.reject {|event| event.status != params[:query]}.paginate(per_page: PAGE_SIZE, page: params[:page], order: 'date DESC')
      else
        query_string = "(lower(name) like ? OR lower(postcode) like ?"
        query_string += query && query.is_numeric? ? " OR host_id = #{query})" : ")"
        @events = @get_together.events.with_number_of_attendees.where(query_string, "%#{params[:query].downcase}%", "%#{params[:query].downcase}%").order('created_at DESC').page(params[:page]).per_page(PAGE_SIZE)
      end
    else 
      @events = @get_together.events.with_number_of_attendees.order('date DESC').page(params[:page]).per_page(PAGE_SIZE)
    end
  rescue Exception => ex
    logger.error ex
    resource_not_found
  end

  def new
    @get_together = @campaign.get_togethers.build(:content_module =>HtmlModule.new)
  end

end
