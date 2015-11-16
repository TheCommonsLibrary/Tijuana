class RadioModule < ContentModule

  option_fields :button_text, :display_defaults
  
  after_initialize :defaults
  
  validates :button_text, :length => { :minimum => 1, :maximum => 64 }

  def self.for_container?(layout_container)
    layout_container == :sidebar
  end
  
  def update_action_attributes_and_validate(params)
    user_call.targets = params[:targets]
    user_call.valid?
  end

  def take_action(params, user, page, email=nil, options={})
  end
  
  def display_defaults?
    self.display_defaults == '1'
  end
  
  private
  
  def defaults
    self.button_text = "Called a show!" unless self.button_text
    self.display_defaults = true unless self.display_defaults
    self.public_activity_stream_template = "{NAME|A member} called their MP and asked them [something]." unless self.public_activity_stream_template
  end

end