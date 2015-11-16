module Admin
  class DaisyChainsController < Admin::AdminController
    skip_authorize_resource # We have no model, which confuses CanCan.
    skip_authorization_check # Anyone with access to the admin interface can see this

    def show
    end

    def switch
      Setting[:auto_daisy_chains] = params[:auto_daisy_chains] == '1'
      redirect_to admin_daisy_chains_path, :notice => 'Daisy chain configuration has been updated.'
    end
  end
end
