class RecommendationModule < ContentModule
  def self.for_container?(layout_container)
    layout_container == :main_content
  end

  def recommendations(user)
    # grab two pages from same pillar (but not existing page)
    # grab two pages from different pillar
    # show community run
    PageSequence.order('created_at desc').limit(5).map{|page_sequence| data_for_page_sequence(page_sequence) }
  end                                                                    

  private

  def data_for_page_sequence(page_sequence)
    page = page_sequence.pages.first
    {
      title: page.name,
      description: page_sequence.html_meta_description,
      image_url: page_sequence.facebook_image,
      page_id: page.id
    }  
  end
end
