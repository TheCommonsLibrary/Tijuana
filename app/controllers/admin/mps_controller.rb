module Admin
  class MpsController < AdminController
    def index
      @parties = {}
      @mps = Mp.by_jurisdiction.paginate(page: params[:page], per_page: 140)
      Party.with_jurisdictions.all.each do |party|
        @parties[party.jurisdiction.id] ||= []
        @parties[party.jurisdiction.id] << [party.id, "#{party} - #{party.jurisdiction}"]
      end
    end

    def update
      @mp = Mp.find params[:id]

      respond_to do |format|
        if @mp.update_attributes(params[:mp])
          format.html { redirect_to(@mp, :notice => 'User was successfully updated.') }
          format.json { respond_with_bip(@mp) }
        else
          format.html { render :action => "edit" }
          format.json { respond_with_bip(@mp) }
        end
      end
    end
  end
end
