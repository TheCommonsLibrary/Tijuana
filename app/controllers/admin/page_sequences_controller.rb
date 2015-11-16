module Admin
  class PageSequencesController < AdminController
    crud_actions_for PageSequence, :parent => Campaign, :redirects => {
      :create  => lambda { admin_page_sequence_path(@page_sequence) },
      :update  => lambda { admin_page_sequence_path(@page_sequence) },
      :destroy => lambda { admin_campaign_path(@campaign) }
    }

    def sort_pages
      @page_sequence.pages.each do |page|
        page.update_attribute(:position, params[:page].index(page.id.to_s) + 1)
      end
      render :nothing => true
    end
    
    def duplicate
      new_sequence = @page_sequence.duplicate      
      redirect_to admin_campaign_path(@campaign), :notice => "'#{@page_sequence.name}' has been duplicated."
    end
  end
end