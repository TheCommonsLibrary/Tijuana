class Admin::RedirectsController < Admin::AdminController
  crud_actions_for Redirect, :redirects => {
    :update  => lambda { admin_redirects_path },
    :destroy => lambda { admin_redirects_path }
  }
  
  def index
    @redirects = Redirect.all
  end

  def create
    @redirect = Redirect.new(params[:redirect])
    @redirect.alias_path = nil if @redirect.alias_path.try(:strip) == ""
    @redirect.alias_domain = nil if @redirect.alias_domain.try(:strip) == ""
    save_and_redirect(:update, :new)
  end

  # override from CrudActions
  def save_record(model, custom_flash)
    model.valid?
    if model.errors.empty?
      model.errors.add(:target, "Link '#{model.target}' cannot be resolved to a valid website.") unless LinksLiveValidator.is_url_reachable?(model.target)
    end

    if model.errors.empty?
      model.save(validate: false)
    end
    model.errors.empty?
  end
end
