class Admin::ImagesController < Admin::AdminController
  RecentImagesToDisplay = 30

  before_filter :recent_images, :only => [:create, :index]

  def index
    @new_image = Image.new
  end

  def new
    @new_image = Image.new
  end

  def show
    @image = Image.find(params[:id])
  end

  def create
    pre_paperclip_opts = { "image_resize" => params["image"]["image_resize"] == "1", 
                           "image_height" => params["image"]["image_height"],
                           "image_width"  => params["image"]["image_width"]}
    @new_image = Image.new(pre_paperclip_opts.merge(params[:image]) )

    if @new_image.save
      flash[:notice] = "Image uploaded."
      redirect_to admin_image_path(@new_image)
    else
      render :action => 'index'
    end
  end

  private

  def recent_images
    @images = Image.latest(RecentImagesToDisplay).to_a
  end
end
