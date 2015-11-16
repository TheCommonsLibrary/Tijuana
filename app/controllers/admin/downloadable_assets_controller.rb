class Admin::DownloadableAssetsController < Admin::AdminController
  RecentAssetsToDisplay = 30

  before_filter :recent_assets, :only => [:create, :index]

  def index
    @asset = DownloadableAsset.new
  end

  def new
    @asset = DownloadableAsset.new
  end

  def show
    @asset = DownloadableAsset.find(params[:id])
  end

  def create
    @asset = DownloadableAsset.new(params[:asset])

    if @asset.save
      flash[:notice] = "File uploaded."
      redirect_to admin_downloadable_asset_path(@asset)
    else
      render :action => 'index'
    end
  end

  private

  def recent_assets
    @assets = DownloadableAsset.latest(RecentAssetsToDisplay).to_a
  end
end
