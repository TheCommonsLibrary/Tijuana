module Admin
  class BlastsController < AdminController
    crud_actions_for Blast, :parent => Push, :redirects => {
      :create  => lambda { admin_push_path(@push) },
      :update  => lambda { admin_push_path(@push) },
      :destroy => lambda { admin_push_path(@push) },
    }

    def deliver
      blast = Blast.find(params[:id])
      if Push.currently_delivering
        flash[:warning] = 'Another push is in progress'
        return redirect_to admin_push_path(blast.push)
      elsif !blast.push.acquire_lock
        flash[:warning] = 'Delivery already in progress.'
        return redirect_to admin_push_path(blast.push)
      else
        deliver_emails(blast)
      end
    end
    
    def deliver_emails(blast)
      limit = params[:limit].blank? ? nil : params[:limit].to_i
      if params[:email_id] == "all"
        blast.send_all_proofed_emails!(limit)
      else
        blast.send_proofed_emails!([params[:email_id]], limit)
      end
      Rails.logger.info blast.push.inspect
      redirect_to admin_push_path(blast.push)
    end
    private :deliver_emails

    def cancel
      blast = Blast.find(params[:id])
      notice = "Delivery cancelled"
      if blast.in_cooling_off_period?
        blast.cancel
        blast.push.release_lock
      else
        notice = 'Unable to cancel blast'
        flash[:error] = notice
        return redirect_to admin_push_path(blast.push)
      end
      redirect_to admin_push_path(blast.push), :notice => notice
    end

  end
end
