module Admin::PageSequencesHelper
  def share_link(page)
    generate_link_text = "Generate Share link"
    if page.acquisition_sources.any?
      text = "View #{pluralize(page.acquisition_sources.count, 'share link')}"
      link_to text, admin_page_acquisition_sources_path(page), target: "_blank"
    else
      link_to generate_link_text, new_admin_page_acquisition_source_path(page), target: "_blank"
    end
  end
end
