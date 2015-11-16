class StaticPage
  def self.global_donation
    @global_donation_page ||= PageSequence.static.where(:name => "Donate").first.pages.first
  end
end