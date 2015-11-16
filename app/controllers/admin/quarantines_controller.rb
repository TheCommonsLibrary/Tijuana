module Admin
  class QuarantinesController < Admin::AdminController
    skip_authorize_resource # We have no model, which confuses CanCan.
    skip_authorization_check # Anyone with access to the admin interface can see this

    def show
    end

    def update_cr_slugs
      Setting.quarantined_controlshift_slugs = (params[:cr_slugs] || '').strip.split(/[, \r\n]+/)
      redirect_to admin_quarantines_path, :notice => 'ControlShift slugs have been saved.'
    end
  end
end
