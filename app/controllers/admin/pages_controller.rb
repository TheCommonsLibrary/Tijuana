module Admin
  class PagesController < AdminController

    crud_actions_for Page, :parent => PageSequence, :redirects => {
        :create => lambda { edit_admin_page_path(@page) },
        :update => lambda { admin_page_sequence_path(@page_sequence) },
        :destroy => lambda { admin_page_sequence_path(@page_sequence) }
    }

    before_filter :find_content_modules, :except => [:new, :create]
    cache_sweeper PageSweeper

    def add_tag
      @page.tag_list.add(params[:tag])
      @page.save!(validate: false)
      render nothing: true
    end

    def remove_tag
      @page.tag_list.remove(params[:tag])
      @page.save!(validate: false)
      render nothing: true
    end

    def update
      do_extended_validation = params[:submit] == "Save & Validate"
      updated_content_modules = update_content_modules_with_params(@all_content_modules, params[:content_modules])
      validate_content_modules(@all_content_modules, do_extended_validation)
      update_and_validate_page(do_extended_validation)

      if @page.errors.empty? && all_records_valid?(@all_content_modules) && @page.reorder_main_content_modules!
        save_updated_content_modules(updated_content_modules)
        save_page
        Mautic.new.create_form_links(@all_content_modules.map(&:id)) if AppConstants.mautic_auth.present?
        msg = "'#{@page.name}' has been updated."
        msg << "<br><br><b>Note:</b> Only Validated HTML, Accordion, Direct Landing Html and Donation modules." if do_extended_validation
        redirect_to admin_page_sequence_path(@page_sequence), :notice => msg
      else
        flash[:error] = "Your changes have NOT BEEN SAVED YET. Please see the errors below."
        render :action => "edit"
      end
    end

    def update_and_validate_page(do_extended_validation)
      @page.attributes = params[:page]
      @page.valid?
      if do_extended_validation
        LinksLiveValidator.validate_each(@page, :thankyou_email_text, @page.thankyou_email_text)
      end
    end

    def save_page
      if @page.errors.empty?
        @page.save(validate: false)
      end
    end

    def add_content_module
      @content_module = params[:type].constantize.new
      @content_module.save!(:validate => false)
      @page.content_module_links.create!(:layout_container => params[:container], :content_module => @content_module)
      @render_bookmark_form_inline = true
      respond_to do |format|
        format.js { render :content_type => "text/html", :partial => "content_module", :locals => {:content_module => @content_module, :layout_container => params[:container]} }
      end
    end

    def remove_content_module
      ContentModuleLink.where(:page_id => @page.id, :content_module_id => params[:content_module_id]).first.destroy
      render :nothing => true
    end

    def sort_content_modules
      params[:content_module].each_with_index do |element, index|
        content_module_link = ContentModuleLink.where(:page_id => @page.id, :content_module_id => element.to_i).first
        content_module_link.position = index + 1
        content_module_link.save!
      end
      render :nothing => true
    end

    def switch_container
      content_module_link = ContentModuleLink.where(:page_id => @page.id, :content_module_id => params[:content_module_id]).first
      content_module_link.layout_container = content_module_link.layout_container == :main_content ? :sidebar : :main_content
      content_module_link.move_to_bottom
      render :nothing => true
    end

    def bookmark_content_module
      bookmark = BookmarkedContentModule.new(:content_module_id => params[:content_module_id], :name => params[:bookmark_name])
      if bookmark.save
        render :nothing => true
      else
        render :text => bookmark.errors.full_messages.first, :status => :bad_request
      end
    end

    def unbookmark_content_module
      BookmarkedContentModule.where(:content_module_id => params[:content_module_id]).destroy_all
      render :nothing => true
    end

    def show_bookmarks
      @layout_container = params[:container].to_sym
      @bookmarks = BookmarkedContentModule.order("created_at DESC").select { |bookmark| bookmark.can_be_added_to?(@page, @layout_container) }
      render :layout => false
    end

    def add_from_bookmarks
      @layout_container = params[:container].to_sym
      @content_module = ContentModule.find(params[:content_module_id])
      @page.content_module_links.create!(:layout_container => @layout_container, :content_module => @content_module)
      @render_bookmark_form_inline = true
      respond_to do |format|
        format.js { render :content_type => "text/html", :partial => "content_module", :locals => {:content_module => @content_module, :layout_container => @layout_container} }
      end
    end

    def unlink_content_module
      link = ContentModuleLink.where(:page_id => @page.id, :content_module_id => params[:content_module_id]).first
      link.content_module = link.content_module.dup
      link.content_module.mautic_id = nil
      link.save!
      respond_to do |format|
        format.js { render :content_type => "text/html", :partial => "content_module", :locals => {:content_module => link.content_module, :layout_container => link.layout_container} }
      end
    end

    private

    def find_content_modules
      @header_content_modules = @page.header_content_modules
      @main_content_modules = @page.main_content_modules
      @sidebar_content_modules = @page.sidebar_content_modules
      @aside_content_modules = @page.aside_content_modules
      @all_content_modules = @page.all_content_modules
    end

    def update_content_modules_with_params(content_modules, params)
      content_modules_with_params = params.blank? ? [] : content_modules.find_all { |cm| params[cm.id.to_s]}
      content_modules_with_params.each { |content_module| content_module.attributes = params[content_module.id.to_s]}
      content_modules_with_params
    end

    def validate_content_modules(content_modules, do_extended_validation)
      content_modules.each do |content_module|
        content_module.valid?
        HtmlValidator.validate_each(content_module, :content, content_module.content) if do_extended_validation && module_handles_extended_validation(content_module)
      end
    end

    def save_updated_content_modules(content_modules)
      content_modules.each do |content_module|
        if content_module.errors.empty?
          content_module.save(validate: false)
        end
      end
    end

    def module_handles_extended_validation(content_module)
      content_module.handles_extended_validation?
    end

    def all_records_valid?(records)
      records.find{|r| r.errors.present?}.blank?
    end
  end
end
