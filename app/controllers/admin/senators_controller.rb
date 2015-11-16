module Admin
  class SenatorsController < AdminController
    def index
      @senators = Senator.by_jurisdiction.order(:region_id).paginate(page: params[:page], per_page: 140)
      @parties = {}
      Party.with_jurisdictions.all.each do |party|
        @parties[party.jurisdiction.id] ||= []
        @parties[party.jurisdiction.id] << [party.id, "#{party} - #{party.jurisdiction}"]
      end
    end

    def update
      @senator = Senator.find params[:id]

      respond_to do |format|
        if @senator.update_attributes(params[:senator])
          format.html { redirect_to(@senator, :notice => 'User was successfully updated.') }
          format.json { respond_with_bip(@senator) }
        else
          format.html { render :action => "edit" }
          format.json { respond_with_bip(@senator) }
        end
      end
    end
  end
end
