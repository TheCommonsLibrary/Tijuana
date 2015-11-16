class BlackInkMerchandiseReport < MerchandiseReport
  def supplier_name
    'Black Ink'
  end

  def to_csv
    CSV.generate do |csv|
      csv << header_row
      merch_donations.all.each do |donation|
        unless item_mapping_key(donation).start_with? 'NONE'
          csv << order_row_for(donation)
        end
      end
    end
  end

  def order_row_for(donation)
    item_qty = item_mapping_key(donation).gsub("'", '')
    [
        item_qty,
        donation.user.first_name,
        donation.user.last_name,
        donation.user.street_address,
        donation.user.suburb,
        donation.user.postcode.state,
        donation.user.postcode.number,
        donation.user.email,
        donation.user.mobile_number.present? ? donation.user.mobile_number : donation.user.home_number
    ]
  end

  def header_row
    [
      'quantity_of_books',
      'first_name',
      'surname',
      'address',
      'suburb',
      'state',
      'postcode',
      'email',
      'phone_number'
    ]
  end
end
