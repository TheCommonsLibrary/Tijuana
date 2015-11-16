# These helper methods can be called in your template to set variables to be used in the layout
# This module should be included in all views globally,
# to do so you may need to add this line to your ApplicationController
#   helper :layout
module LayoutHelper
  def title(page_title, show_title = true)
    content_for(:title) { raw(page_title) }
    @show_title = show_title
  end

  def show_title?
    @show_title
  end

  def robots_content
    Rails.env.production? ? 'noodp' : 'noindex, nofollow, noarchive, nosnippet, noodp, notranslate, noimageindex'
  end

  def open_graph_description
    case
      when @page
        @page.page_sequence.html_meta_description
      when @event
        @event.get_together.html_meta_description
      when @get_together
        @get_together.html_meta_description
      else
        AppConstants.default_page_description
    end
  end

  def open_graph_share_image_path()
    case
      when @page
        @page.page_sequence.facebook_image
      when @event
        @event.get_together.facebook_image
      when @get_together
        @get_together.facebook_image
      else
        URI.join(root_url, asset_path('public/getup_logo.png'))
    end
  end

  def open_graph_title
    case
      when @page
        @page.page_sequence.landing_page.name
      when @event
        @event.name
      when @get_together
        @get_together.name
      else
        AppConstants.default_page_title
    end
  end
end
