class UpdateAddressService
  def self.update_records(record_row)
    record_row.user.update_attributes(
        street_address: record_row.street_address,
        suburb: record_row.suburb,
        postcode: record_row.postcode,
        address_validated_at: Time.now.strftime('%Y-%m-%d %H:%M:%S')
    )
  end
end