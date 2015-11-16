class RepresentativeApiSerializer < ActiveModel::Serializer
  attributes :name, :phone_number, :electorate, :senator

  def name
    object[:representative].full_name
  end

  def phone_number
    number = object[:representative].office_phone.gsub(/(?!^\+)\D*/, '').gsub(/^0/, '')
    number.start_with?('61') ? number : '61' + number
  end

  def electorate
    object[:electorate]
  end

  def senator
    object[:representative].is_a?(Senator)
  end

end
