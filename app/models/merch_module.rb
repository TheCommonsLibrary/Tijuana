class MerchModule < DonationModule

  def handles_address?
    true
  end

  def update_action_attributes_and_validate(params)
    super(params)
    if validate_address?
      @postal_address = PostalAddress.new(params[:postal_address])
      @postal_address.valid?
    end
  end

  def take_action(user, page, email=nil, params=nil, options={})
    return false unless postal_address.errors.blank?
    if validate_address?
      validate_and_save_address(user) && call_parent_class_take_action(user, page, email, params, options)
    else
      call_parent_class_take_action(user, page, email, params, options)
    end
  end

  def defaults
    super
    self.public_activity_stream_template = '{NAME|A member} donated for [some merch].' unless self.public_activity_stream_template
    self.disable_paypal = true # force no paypal
  end

  def postal_address
    @postal_address ||= PostalAddress.new
  end

  def multistep_form_shown?
    false
  end
  
  private

  def validate_address?
   !donation.respond_to?(:quantity) || (donation.respond_to?(:quantity) && donation.quantity != 'NONE')
  end

  def validate_and_save_address(user)
    begin
      if @postal_address.manual_mode?
        update_address_details_of_user(user) && validate_details_set_using_manual_address_fields(user)
      else
        address_service.populate_user_address_from_search_result_id!(user, @postal_address.search_outcome)
      end
      return true
    rescue TotalCheckSearchResultIdExpiryException
      @postal_address.search_outcome = address_service.get_first_search_result_id(@postal_address.address_search)
      validate_and_save_address(user)
    rescue Exception
      @postal_address.errors.add(:address_search, '^Invalid delivery address.')
      return false
    end
  end

  def validate_details_set_using_manual_address_fields(user)
    @postal_address.errors.add(:postcode_number, '^Please enter a valid postcode') if user.postcode_id.nil?
    @postal_address.errors.empty?
  end

  def update_address_details_of_user(user)
    user.street_address = postal_address.street_address
    user.suburb = postal_address.suburb
    user.postcode_number = postal_address.postcode_number
    user.save
  end

  def address_service
    ADDRESS_SERVICE
  end

  def call_parent_class_take_action(user, page, email, params, options)
    self.class.superclass.instance_method(:take_action).bind(self).call(user, page, email, params, options)
  end
end
