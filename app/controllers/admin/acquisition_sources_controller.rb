class Admin::AcquisitionSourcesController < Admin::AdminController
  crud_actions_for AcquisitionSource, parent: Page, redirects: { create: lambda { admin_page_acquisition_sources_path(@page) } }

  private

  def save_and_redirect(success_redirect, error_action)
    model.user = current_user
    custom_flash = {}
    if save_record(model, custom_flash)
      update_flash(custom_flash, {notice:"'#{model.name}' has been saved."})
      redirect_to crud_redirect(success_redirect)
    else
      update_flash(custom_flash, {error:ERROR_MESSAGE})
      render :action => error_action
    end
  end
end
