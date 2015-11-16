class UpdatedAddressRow
  def initialize(row)
    @row = row
  end

  def user
    user = User.find_by_email(@row['email'])
    raise "User not found #{@row['email']}" unless user
    user
  end

  def street_address
    @row['street_address']
  end

  def suburb
    @row['suburb']
  end

  def postcode
    @row['postcode'] = @row['postcode'].length == 3 ? "0#{@row['postcode']}" : @row['postcode']
    postcode = Postcode.find_by_number(@row['postcode'])
    raise "Invalid postcode #{@row['postcode']}" unless postcode
    postcode
  end

end
