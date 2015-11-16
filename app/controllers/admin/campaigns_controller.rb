require 'csv'
module Admin
  class CampaignsController < AdminController
    PAGE_SIZE = 5
        
    crud_actions_for Campaign, :redirects => {
      :create  => lambda { admin_campaign_path(@campaign) },
      :update  => lambda { admin_campaign_path(@campaign) },
      :destroy => lambda { admin_campaigns_path }
    }
    
    def index
      if params[:query]
        @campaigns = Campaign.where("lower(name) like ?", ["%#{params[:query].downcase}%"]).order('created_at DESC').page(params[:page]).per_page(PAGE_SIZE)
      else
        @campaigns = Campaign.order('created_at DESC').page(params[:page]).per_page(PAGE_SIZE)
      end
    end
    
    def show
      @sequences = PageSequence.order('created_at DESC').where(campaign_id: @campaign.id).page(params[:page]).per_page(PAGE_SIZE)
      @pushes = Push.order('created_at DESC').where(campaign_id: @campaign.id).page(params[:page]).per_page(PAGE_SIZE)
      @get_togethers = GetTogether.order('created_at DESC').where(campaign_id: @campaign.id).page(params[:page]).per_page(PAGE_SIZE)

      @stats = Campaign.paginate_by_sql(@campaign.build_stats_query, :per_page => PAGE_SIZE, :page => params[:page] || 1)
    end
    
    def ask_stats_report
      authorize! :export, AskStatsTable
      report = AskStatsTable.new(Campaign.find_by_sql(@campaign.build_stats_query))
      send_data(report.to_csv, :type => 'text/csv', :filename => "Ask Stats for #{@campaign.name} (#{Date.today}).csv")
    end
  end
end
