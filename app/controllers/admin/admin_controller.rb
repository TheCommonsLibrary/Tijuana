module Admin
  class AdminController < ApplicationController
    include CrudActions
    authorize_resource
    check_authorization

    before_filter :authenticate_user!
    before_filter :authenticate_admin!
    before_filter :set_current_user
    before_filter :set_nocache_headers
    before_filter :set_url_options

    def set_url_options
      if request.path_parameters[:bare]
        self.default_url_options = {:bare => "bare"}
        self.class.layout "admin/admin-bare"
      else
        self.default_url_options = { :bare => nil }
        self.class.layout "admin/admin"
      end
    end

    def authenticate_admin!
      if current_user && !(current_user.is_admin? || current_user.is_volunteer?)
        flash[:error] = "Only administrators can view the admin pages"
        redirect_to root_path
      end
    end

    def set_current_user
      User.current_user = current_user
    end

    def set_nocache_headers
      response.headers["Cache-Control"] = "no-cache, no-store, max-age=0, must-revalidate"
      response.headers["Pragma"] = "no-cache"
    end
  end
end
