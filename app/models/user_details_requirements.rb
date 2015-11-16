module UserDetailsRequirements

  def self.included(base)
    base.serialize :required_user_details
  end

  def required_user_details
    serialized = read_attribute(:required_user_details)
    write_attribute(:required_user_details, serialized = {}) if serialized.nil?
    serialized
  end

  def required_user_details=(new_details)
    symbolize = new_details.inject({}) { |memo, (k,v)| memo[k.to_sym] = v.to_sym; memo }
    write_attribute(:required_user_details, symbolize)
  end

  def user_details_that_are(action)
    required_user_details.select { |k, v| v.to_sym == action.to_sym }.keys
  end

  def required_user_details_includes_address?
    required_user_details[:street_address] != :hidden || 
    required_user_details[:suburb] != :hidden || 
    required_user_details[:postcode_number] != :hidden
  end

  DEFAULT_REQUIRED_USER_DETAILS = [
      {:field => :first_name, :default => :required, :label => "First Name"},
      {:field => :last_name, :default => :required, :label => "Last Name"},
      {:field => :postcode_number, :default => :required, :label => "Postcode"},
      {:field => :mobile_number, :default => :optional, :label => "Mobile"},
      {:field => :home_number, :default => :hidden, :label => "Home"},
      {:field => :street_address, :default => :hidden, :label => "Street Address"},
      {:field => :suburb, :default => :hidden, :label => "Suburb"},
      {:field => :country_iso, :default => :hidden, :label => "Country"}
  ]

end
