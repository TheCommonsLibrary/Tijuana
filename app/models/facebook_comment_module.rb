class FacebookCommentModule < ContentModule
  option_fields :target_facebook_id

  def self.for_container?(layout_container)
    layout_container == :sidebar
  end
end
