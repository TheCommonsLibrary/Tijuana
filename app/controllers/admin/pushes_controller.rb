module Admin
  class PushesController < AdminController
    crud_actions_for Push, :parent => Campaign, :redirects => {
      :create  => lambda { admin_push_path(@push) },
      :update  => lambda { admin_push_path(@push) },
      :destroy => lambda { admin_campaign_path(@campaign) }
    }

    # overridden from Admin::CrudActions to improve page load
    def find_model
      model_class.includes(:blasts => :emails).where(:id => params[:id]).first
    end
    
    def email_stats_report
      authorize! :export, EmailStatsTable
      report = EmailStatsTable.new(@push.blasts.map(&:emails).flatten)
      send_data(report.to_csv, :type => 'text/csv', :filename => "Email Stats for #{@push.name} (#{Date.today}).csv")
    end

    def stats
      render :partial => "email_stats", :locals => {:stats_table => EmailStatsTable.new(@push.blasts.map(&:emails).flatten)}
    end

    def deliver_multiblast
      email_ids = params[:email_ids].split(',').map(&:to_i)
      if @push.multiblast_valid?(email_ids)
        if @push.acquire_lock
          @push.send_multiblast!(email_ids)
        else
          flash[:warning] = 'Delivery already in progress.'
        end
        redirect_to admin_push_path(@push)
      else
        render :show
      end
    end

    def cancel_multiblast
      @push.release_lock
      case @push.cancel_multiblast!
        when InterruptableJob::CANCEL_STATUS[:destroyed]
          message = {notice: "Multi blast cancelled."}
        when InterruptableJob::CANCEL_STATUS[:interrupted]
          message = {notice: "Multi blast interrupted - please wait for current job to finish."}
        else
          message = {error: "Multi blast cannot be cancelled"}
      end
      redirect_to admin_push_path(@push), flash: message
    end

    def notes
      if note = Note.create_or_update(params[:note])
        render :text => note.value.blank? ? "" : note.value.html_linebreaks , :status => 200, :layout => false
      else
        render :text => "There was a problem trying to edit your note. Please contact the administrator.", :status => 500, :layout => false
      end
    end

    def duplicate
      redirect_to admin_push_path(@push.duplicate), flash: {notice: 'Push successfully duplicated'}
    end
  end
end
