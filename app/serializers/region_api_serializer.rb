class RegionApiSerializer < ActiveModel::Serializer
  attributes :name, :phone_number, :electorate

  def name
    object.senators.first.full_name
  end

  def phone_number
    number = object.senators.first.office_phone.gsub(/(?!^\+)\D*/, '').gsub(/^0/, '')
    number.start_with?('61') ? number : '61' + number
  end

  def electorate
    object.name
  end

end
