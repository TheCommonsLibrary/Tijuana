class BookmarkedContentModule < ActiveRecord::Base
  belongs_to :content_module
  
  validates :content_module, :presence => true
  validates :content_module_id, :uniqueness => { :message => "has already been bookmarked." }
  validates :name, :length => { :maximum => 64, :minimum => 3 }
  validates :name, :uniqueness => true
  
  def can_be_added_to?(page, layout_container)
    return false unless content_module.class.for_container?(layout_container)
    return false if page.has_an_ask? && content_module.is_ask?
    return false if page.has_tell_a_friend? && content_module.is_a?(TellAFriendModule)
    return false if page.content_modules.map(&:id).include?(content_module.id)
    return true
  end
end