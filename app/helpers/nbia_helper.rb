module NbiaHelper
  def choose_nbia_layout(page)
    (page.page_sequence.name.downcase == "site" && page.name.downcase.start_with?("home")) ? "home" : "show"
  end
end
