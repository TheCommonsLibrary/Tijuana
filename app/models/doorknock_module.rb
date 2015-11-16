class DoorknockModule < ContentModule
  option_fields :button_text

  after_initialize :defaults

  def self.for_container?(layout_container)
    [:sidebar].include?(layout_container)
  end

  def take_action(user, page, email=nil, params=nil, options={})
    @all_street_ids = params[:street_id].reject(&:blank?).uniq
    @street_user_modules = @all_street_ids.map {|street_id| StreetUserModule.new( content_module: self, user: user, page: page, street_id: street_id)}
    @street_user_modules.each(&:valid?)
    if invalid_street_user_modules.present?
      false
    else
      @street_user_modules.each do |street_user_module|
        create_action street_user_module, options
      end
    end
  end

  def update_action_attributes_and_validate(params)
  end

  def invalid_street_user_modules
    @street_user_modules.present? ? @street_user_modules.reject(&:valid?) : []
  end

  def suburb_names
    Street.suburbs.order(:suburb_name).map(&:suburb_name)
  end

  def ask_module_text
    streets.map{|street| "#{street.name}, #{street.suburb_name}"}.join("\n")
  end

  def defaults
    self.button_text = "I'll take it!" unless self.button_text
    self.public_activity_stream_template = "{NAME|A member} is doorknocking in their [neighbourhood]." unless self.public_activity_stream_template
  end

  private

  def streets
    @street_user_modules.map(&:street)
  end
end
