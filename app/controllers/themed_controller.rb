class ThemedController < ApplicationController

 before_filter :view_path_filter
 def view_path_filter
   prepend_view_path("app/views/themes/" + @page.page_sequence.theme.name.downcase)
 end
 private :view_path_filter

end