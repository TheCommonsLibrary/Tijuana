class Admin::HomepagesController < Admin::AdminController
  def edit
    @homepage = Homepage.first
  end
  
  def update
    @homepage = Homepage.first
    if @homepage.update_attributes(params[:homepage])
      redirect_to admin_root_path, :notice => "Homepage has been updated."
    else
      render :action => "edit"
    end
  end
end