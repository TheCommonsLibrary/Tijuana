class OccMerchandiseReport < MerchandiseReport
  def supplier_name
    'OCC'
  end

  def to_csv
    CSV.generate do |csv|
      merch_donations.all.each do |donation|
        unless item_mapping_key(donation).start_with? 'NONE'
          csv << order_row_for(donation)
          csv << item_row_for(donation)
        end
      end
    end
  end

  def orderId(donation)
    "GETUP#{donation.id}"
  end

  def order_row_for(donation)
    [
        'ORDER',
        orderId(donation),
        donation.user.first_name,
        donation.user.last_name,
        '', #company name
        donation.user.street_address,
        '', #street2
        donation.user.suburb,
        donation.user.postcode.state,
        donation.user.postcode.number,
        donation.user.country_iso,
        donation.user.mobile_number.present? ? donation.user.mobile_number : donation.user.home_number,
        donation.user.email,
        donation.user.email,
        donation.payment_method,
        donation.amount_in_dollars,
        0, #insurance fee
        0, # shipping costs
        '', #shipping instructions
        donation.created_at.strftime('%d/%m/%Y %T'),
        'Paid',
        'eParcel',
        '' #consignment number
    ]
  end

  def item_row_for(donation)
    item_info = donation.content_module.custom(:item_mapping)[item_mapping_key(donation)]
    [
        'ITEM',
        orderId(donation),
        item_info[:sku],
        item_info[:title],
        donation.amount_in_dollars,
        1, # quantity
        item_info[:weight],
        '', #supply code
        '', # attributes
        '', # origin country
        '', # length
        '', # width
        '' # height
    ]
  end
end
