class Admin::StaticPagesController < Admin::AdminController
  skip_authorize_resource # We have no static page model, which confuses CanCan.
  skip_authorization_check # Anyone with access to the admin interface can see the static pages index page.
end