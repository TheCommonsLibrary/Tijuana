module Admin
  class MergesController < Admin::AdminController
    crud_actions_for Merge, :redirects => {
      :destroy => lambda { admin_merges_path }
    }

    def index
      pagination_options = {:per_page => 20, :page => params[:page]}
      pagination_options.merge!(:conditions => ["lower(name) like ?", "%#{params[:query].downcase}%"]) if params[:query]
      @merges = Merge.order('updated_at DESC').paginate(pagination_options)
    end

    def new
      @merge = Merge.new
    end

    def whitelist
      render :whitelist_form
    end

    def update_whitelist
      if SCrypt::Password.new(AppConstants.merge_tokens_password) == params[:password]
        Setting[:whitelist_merge_tokens] = (params[:merge_tokens] || '').split("\n").map(&:strip).join("\n")
        redirect_to whitelist_admin_merges_path, :notice => 'Whitelist has been updated.'
      else
        redirect_to whitelist_admin_merges_path, :alert => 'Incorrect password.'
      end
    end

    def edit
      @merge = Merge.find params[:id]
    end

    def update
      @merge = Merge.find params[:id]
      begin
        Merge.transaction do
          @merge.updated_at = Time.now
          @merge.update_attributes!(params[:merge])
          if params[:upload_file]
            @merge.merge_records.destroy_all 
            raise ActiveRecord::Rollback unless MergeUploader.create_merge_records?(@merge, params[:upload_file])
          end

          MergeCache.clear(@merge)
          return redirect_to admin_merges_path, notice: "Merge #{@merge.name} updated"
        end
      rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotSaved
      end
      render :edit
    end

    def create
      Merge.transaction do
        @merge = Merge.new(params[:merge])
        if @merge.save && MergeUploader.create_merge_records?(@merge, params[:upload_file])
          return redirect_to admin_merges_path, notice: "Merge '#{@merge.name}' Updated."
        else
          raise ActiveRecord::Rollback
        end
      end
      render :new
    end
  end
end
